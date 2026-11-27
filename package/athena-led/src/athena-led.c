// [VERIFIED-GOLDEN: athena-led-pro-c-daemon | 2026-11-27 | DO NOT MODIFY UNLESS TARGETED]
/*
 * athena-led.c - Pure-C Matrix & RGB Status Controller for JDCloud RE-CS-02 (Athena)
 *
 * Hardware Architecture (IPQ6018 / JDCloud RE-CS-02):
 *  - Dual TM1628/AIP1628 7x10 LED Controllers (27x5 dot matrix + 4 side icons)
 *    connected to Qualcomm TLMM (1000000.pinctrl) offsets:
 *      stbLeft = 69, stbRight = 70, clk = 73, dio = 74
 *  - Side icon bitmask (14th byte of rightScreen):
 *      bit0 (0x01) = time clock icon
 *      bit1 (0x02) = medal / VIP / Mesh icon
 *      bit2 (0x04) = upload arrow icon
 *      bit3 (0x08) = download arrow icon
 *  - Front RGB LED bar (/sys/class/leds/{red,green,blue}:status):
 *      red (GPIO 57), green (GPIO 58), blue (GPIO 79)
 *  - Top/Side physical screen button (GPIO 71 -> BTN_1) sends SIGUSR1 to cycle
 *    Normal Brightness -> Dim (1) -> Screen Off -> Normal Brightness.
 *
 * GPIO Backend Priority:
 *  1. Linux GPIO Character Device v2 ioctl (/dev/gpiochip*) - Kernel 5.10 / 6.12 / 6.18+
 *     Immune to CONFIG_GPIO_SYSFS removal and dynamic gpiochip base shifts.
 *  2. Linux GPIO Character Device v1 ioctl (/dev/gpiochip*) fallback.
 *  3. Sysfs GPIO (/sys/class/gpio) with dynamic gpiochip base lookup (for Lab/legacy).
 */

#define _GNU_SOURCE
#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>
#include <signal.h>

#ifdef __linux__
#include <linux/gpio.h>
#endif

/* Hardware TLMM pin offsets on JDCloud RE-CS-02 */
#define PIN_OFFSET_STB_LEFT   69
#define PIN_OFFSET_STB_RIGHT  70
#define PIN_OFFSET_CLK        73
#define PIN_OFFSET_DIO        74

/* TM1628 Commands */
#define TM1628_CMD_DISP_MODE  0x03  /* 7 grids x 10 segments */
#define TM1628_CMD_DATA_MODE  0x40  /* Write data, auto-increment address */
#define TM1628_CMD_ADDR_ZERO  0xC0  /* Start at display address 0x00 */
#define TM1628_CMD_CTRL_ON    0x88  /* Display ON + 3-bit brightness (0..7) */
#define TM1628_CMD_CTRL_OFF   0x80  /* Display OFF */

/* Side LED icon bits */
#define ICON_TIME      0x01
#define ICON_MEDAL     0x02
#define ICON_UPLOAD    0x04
#define ICON_DOWNLOAD  0x08

/* Traffic activity threshold for dynamic upload/download arrows (bytes/sec) */
#define NET_ACTIVE_BPS 16384ULL

static volatile sig_atomic_t g_stop = 0;
static volatile sig_atomic_t g_usr1_toggle = 0;

static void on_signal(int sig) {
    if (sig == SIGUSR1) {
        g_usr1_toggle = 1;
    } else {
        g_stop = 1;
    }
}

/* ==========================================================================
 * 1. PRECISE SUB-MICROSECOND / MICROSECOND DELAY FOR TM1628 CLOCK PACING
 * ========================================================================== */
static inline void tm1628_delay_ns(long ns) {
    struct timespec start, now;
    if (clock_gettime(CLOCK_MONOTONIC, &start) != 0)
        return;
    for (;;) {
        if (clock_gettime(CLOCK_MONOTONIC, &now) != 0)
            break;
        long elapsed = (now.tv_sec - start.tv_sec) * 1000000000L + (now.tv_nsec - start.tv_nsec);
        if (elapsed >= ns)
            break;
    }
}

/* ==========================================================================
 * 2. MULTI-BACKEND GPIO DRIVER (CHARDEV V2 -> CHARDEV V1 -> SYSFS)
 * ========================================================================== */
typedef enum {
    GPIO_BACKEND_NONE = 0,
    GPIO_BACKEND_CDEV_V2,
    GPIO_BACKEND_CDEV_V1,
    GPIO_BACKEND_SYSFS
} gpio_backend_t;

typedef struct {
    gpio_backend_t backend;
    int line_fd;          /* For CDEV v2 / v1 */
    uint8_t shadow[4];    /* Cached line states: [0]=stbL, [1]=stbR, [2]=clk, [3]=dio */
    int sysfs_pins[4];    /* Global GPIO numbers for sysfs */
    int sysfs_fds[4];     /* Open value fds for sysfs */
    const char *sysfs_root;
} athena_gpio_t;

enum {
    IDX_STB_L = 0,
    IDX_STB_R = 1,
    IDX_CLK   = 2,
    IDX_DIO   = 3
};

static int match_tlmm_label(const char *name, const char *label, uint32_t lines) {
    if (label && (strstr(label, "1000000.pinctrl") || strstr(label, "tlmm") || strstr(label, "msmgpio")))
        return 1;
    if (name && (strstr(name, "1000000.pinctrl") || strstr(name, "tlmm")))
        return 1;
    if (lines >= 80 && lines <= 256)
        return 1;
    return 0;
}

#if defined(__linux__) && defined(GPIO_V2_GET_LINE_IOCTL)
static int gpio_try_cdev_v2(athena_gpio_t *g) {
    for (int idx = 0; idx < 8; idx++) {
        char devpath[64];
        snprintf(devpath, sizeof(devpath), "/dev/gpiochip%d", idx);
        int chip_fd = open(devpath, O_RDONLY | O_CLOEXEC);
        if (chip_fd < 0)
            continue;

        struct gpiochip_info cinfo;
        memset(&cinfo, 0, sizeof(cinfo));
        if (ioctl(chip_fd, GPIO_GET_CHIPINFO_IOCTL, &cinfo) < 0 ||
            !match_tlmm_label(cinfo.name, cinfo.label, cinfo.lines) ||
            cinfo.lines <= PIN_OFFSET_DIO) {
            close(chip_fd);
            continue;
        }

        struct gpio_v2_line_request req;
        memset(&req, 0, sizeof(req));
        req.offsets[0] = PIN_OFFSET_STB_LEFT;
        req.offsets[1] = PIN_OFFSET_STB_RIGHT;
        req.offsets[2] = PIN_OFFSET_CLK;
        req.offsets[3] = PIN_OFFSET_DIO;
        req.num_lines = 4;
        strncpy(req.consumer, "athena-led", sizeof(req.consumer) - 1);
        req.config.flags = GPIO_V2_LINE_FLAG_OUTPUT;
        req.config.num_attrs = 1;
        req.config.attrs[0].attr.id = GPIO_V2_LINE_ATTR_ID_OUTPUT_VALUES;
        req.config.attrs[0].mask = 0x0F;
        req.config.attrs[0].attr.values = 0x07; /* stbL=1, stbR=1, clk=1, dio=0 */

        int rc = ioctl(chip_fd, GPIO_V2_GET_LINE_IOCTL, &req);
        close(chip_fd);
        if (rc == 0 && req.fd >= 0) {
            g->backend = GPIO_BACKEND_CDEV_V2;
            g->line_fd = req.fd;
            g->shadow[0] = 1;
            g->shadow[1] = 1;
            g->shadow[2] = 1;
            g->shadow[3] = 0;
            return 0;
        }
    }
    return -1;
}
#endif

#if defined(__linux__) && defined(GPIO_GET_LINEHANDLE_IOCTL)
static int gpio_try_cdev_v1(athena_gpio_t *g) {
    for (int idx = 0; idx < 8; idx++) {
        char devpath[64];
        snprintf(devpath, sizeof(devpath), "/dev/gpiochip%d", idx);
        int chip_fd = open(devpath, O_RDONLY | O_CLOEXEC);
        if (chip_fd < 0)
            continue;

        struct gpiochip_info cinfo;
        memset(&cinfo, 0, sizeof(cinfo));
        if (ioctl(chip_fd, GPIO_GET_CHIPINFO_IOCTL, &cinfo) < 0 ||
            !match_tlmm_label(cinfo.name, cinfo.label, cinfo.lines) ||
            cinfo.lines <= PIN_OFFSET_DIO) {
            close(chip_fd);
            continue;
        }

        struct gpiohandle_request req;
        memset(&req, 0, sizeof(req));
        req.lineoffsets[0] = PIN_OFFSET_STB_LEFT;
        req.lineoffsets[1] = PIN_OFFSET_STB_RIGHT;
        req.lineoffsets[2] = PIN_OFFSET_CLK;
        req.lineoffsets[3] = PIN_OFFSET_DIO;
        req.lines = 4;
        req.flags = GPIOHANDLE_REQUEST_OUTPUT;
        req.default_values[0] = 1;
        req.default_values[1] = 1;
        req.default_values[2] = 1;
        req.default_values[3] = 0;
        strncpy(req.consumer_label, "athena-led", sizeof(req.consumer_label) - 1);

        int rc = ioctl(chip_fd, GPIO_GET_LINEHANDLE_IOCTL, &req);
        close(chip_fd);
        if (rc == 0 && req.fd >= 0) {
            g->backend = GPIO_BACKEND_CDEV_V1;
            g->line_fd = req.fd;
            g->shadow[0] = 1;
            g->shadow[1] = 1;
            g->shadow[2] = 1;
            g->shadow[3] = 0;
            return 0;
        }
    }
    return -1;
}
#endif

static int read_small_file(const char *path, char *buf, size_t sz) {
    if (!buf || sz == 0)
        return -1;
    buf[0] = '\0';
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0)
        return -1;
    ssize_t n = read(fd, buf, sz - 1);
    close(fd);
    if (n < 0)
        return -1;
    buf[n] = '\0';
    while (n > 0 && (buf[n - 1] == '\n' || buf[n - 1] == '\r' || buf[n - 1] == ' ' || buf[n - 1] == '\t')) {
        buf[--n] = '\0';
    }
    return (int)n;
}

static int write_small_file(const char *path, const char *val) {
    int fd = open(path, O_WRONLY | O_CLOEXEC);
    if (fd < 0)
        return -1;
    size_t len = strlen(val);
    ssize_t n = write(fd, val, len);
    close(fd);
    return (n == (ssize_t)len) ? 0 : -1;
}

static int write_state_file(const char *path, const char *val) {
    int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
    if (fd < 0)
        return -1;
    size_t len = strlen(val);
    ssize_t n = write(fd, val, len);
    close(fd);
    return (n == (ssize_t)len) ? 0 : -1;
}

static int discover_sysfs_gpio_base(const char *sysfs_gpio_dir) {
    DIR *d = opendir(sysfs_gpio_dir);
    int fallback_base = -1;
    if (d) {
        struct dirent *ent;
        while ((ent = readdir(d)) != NULL) {
            if (strncmp(ent->d_name, "gpiochip", 8) != 0)
                continue;
            char lpath[512], bpath[512], npath[512];
            char label[64] = {0}, base_s[32] = {0}, ngpio_s[32] = {0};
            snprintf(lpath, sizeof(lpath), "%s/%s/label", sysfs_gpio_dir, ent->d_name);
            snprintf(bpath, sizeof(bpath), "%s/%s/base", sysfs_gpio_dir, ent->d_name);
            snprintf(npath, sizeof(npath), "%s/%s/ngpio", sysfs_gpio_dir, ent->d_name);
            if (read_small_file(bpath, base_s, sizeof(base_s)) < 0)
                continue;
            int base = atoi(base_s);
            read_small_file(lpath, label, sizeof(label));
            read_small_file(npath, ngpio_s, sizeof(ngpio_s));
            int ngpio = atoi(ngpio_s);
            if (strstr(label, "1000000.pinctrl") || strstr(label, "tlmm") || strstr(label, "msmgpio")) {
                closedir(d);
                return base;
            }
            if (ngpio >= 80 && fallback_base < 0)
                fallback_base = base;
        }
        closedir(d);
    }
    if (fallback_base >= 0)
        return fallback_base;

    /* Legacy fallback check via /etc/openwrt_release */
    char rel[512];
    if (read_small_file("/etc/openwrt_release", rel, sizeof(rel)) > 0 && strstr(rel, "QWRT"))
        return 432; /* 432 + 69 = 501 */
    return 512;     /* 512 + 69 = 581 */
}

static int gpio_try_sysfs(athena_gpio_t *g) {
    const char *root = getenv("ATHENA_SYSFS_GPIO_DIR");
    if (!root || !*root)
        root = "/sys/class/gpio";
    g->sysfs_root = root;

    int base = discover_sysfs_gpio_base(root);
    const int offsets[4] = {
        PIN_OFFSET_STB_LEFT,
        PIN_OFFSET_STB_RIGHT,
        PIN_OFFSET_CLK,
        PIN_OFFSET_DIO
    };

    for (int i = 0; i < 4; i++)
        g->sysfs_fds[i] = -1;

    for (int i = 0; i < 4; i++) {
        int pin = base + offsets[i];
        g->sysfs_pins[i] = pin;
        char dir_path[256], val_path[256], exp_path[256], pin_str[32];
        snprintf(dir_path, sizeof(dir_path), "%s/gpio%d/direction", root, pin);
        snprintf(val_path, sizeof(val_path), "%s/gpio%d/value", root, pin);
        struct stat st;
        if (stat(val_path, &st) != 0) {
            snprintf(exp_path, sizeof(exp_path), "%s/export", root);
            snprintf(pin_str, sizeof(pin_str), "%d", pin);
            if (write_small_file(exp_path, pin_str) != 0)
                return -1;
            usleep(10000);
        }
        if (write_small_file(dir_path, "out") != 0)
            return -1;
        int fd = open(val_path, O_WRONLY | O_CLOEXEC);
        if (fd < 0)
            return -1;
        g->sysfs_fds[i] = fd;
    }

    g->backend = GPIO_BACKEND_SYSFS;
    g->shadow[0] = 1;
    g->shadow[1] = 1;
    g->shadow[2] = 1;
    g->shadow[3] = 0;
    return 0;
}

static int athena_gpio_init(athena_gpio_t *g) {
    memset(g, 0, sizeof(*g));
    g->line_fd = -1;
    for (int i = 0; i < 4; i++)
        g->sysfs_fds[i] = -1;

    const char *force_sysfs = getenv("ATHENA_SYSFS_GPIO_DIR");
    if (!force_sysfs || !*force_sysfs) {
#if defined(__linux__) && defined(GPIO_V2_GET_LINE_IOCTL)
        if (gpio_try_cdev_v2(g) == 0)
            return 0;
#endif
#if defined(__linux__) && defined(GPIO_GET_LINEHANDLE_IOCTL)
        if (gpio_try_cdev_v1(g) == 0)
            return 0;
#endif
    }
    return gpio_try_sysfs(g);
}

static void athena_gpio_flush(athena_gpio_t *g, uint8_t mask) {
#if defined(__linux__) && defined(GPIO_V2_LINE_SET_VALUES_IOCTL)
    if (g->backend == GPIO_BACKEND_CDEV_V2) {
        struct gpio_v2_line_values vals;
        vals.mask = mask;
        vals.bits = (uint64_t)(g->shadow[0] & 1) |
                    ((uint64_t)(g->shadow[1] & 1) << 1) |
                    ((uint64_t)(g->shadow[2] & 1) << 2) |
                    ((uint64_t)(g->shadow[3] & 1) << 3);
        (void)ioctl(g->line_fd, GPIO_V2_LINE_SET_VALUES_IOCTL, &vals);
        tm1628_delay_ns(750);
        return;
    }
#endif
#if defined(__linux__) && defined(GPIOHANDLE_SET_LINE_VALUES_IOCTL)
    if (g->backend == GPIO_BACKEND_CDEV_V1) {
        struct gpiohandle_data data;
        memset(&data, 0, sizeof(data));
        for (int i = 0; i < 4; i++)
            data.values[i] = g->shadow[i];
        (void)ioctl(g->line_fd, GPIOHANDLE_SET_LINE_VALUES_IOCTL, &data);
        tm1628_delay_ns(750);
        return;
    }
#endif
    if (g->backend == GPIO_BACKEND_SYSFS) {
        for (int i = 0; i < 4; i++) {
            if ((mask & (1U << i)) && g->sysfs_fds[i] >= 0) {
                const char c = g->shadow[i] ? '1' : '0';
                (void)write(g->sysfs_fds[i], &c, 1);
            }
        }
        tm1628_delay_ns(500);
    }
}

static inline void athena_gpio_set_pin(athena_gpio_t *g, int idx, uint8_t val) {
    g->shadow[idx] = val ? 1 : 0;
    athena_gpio_flush(g, (uint8_t)(1U << idx));
}

static inline void athena_gpio_clock_bit(athena_gpio_t *g, uint8_t bit) {
    /* Pull CLK low and set DIO simultaneously, hold, then pull CLK high */
    g->shadow[IDX_CLK] = 0;
    g->shadow[IDX_DIO] = bit ? 1 : 0;
    athena_gpio_flush(g, (1U << IDX_CLK) | (1U << IDX_DIO));
    g->shadow[IDX_CLK] = 1;
    athena_gpio_flush(g, (1U << IDX_CLK));
}

static void athena_gpio_close(athena_gpio_t *g) {
    if (g->line_fd >= 0) {
        close(g->line_fd);
        g->line_fd = -1;
    }
    if (g->backend == GPIO_BACKEND_SYSFS && g->sysfs_root) {
        char unexp_path[256], pin_str[32];
        snprintf(unexp_path, sizeof(unexp_path), "%s/unexport", g->sysfs_root);
        for (int i = 0; i < 4; i++) {
            if (g->sysfs_fds[i] >= 0) {
                close(g->sysfs_fds[i]);
                g->sysfs_fds[i] = -1;
            }
            snprintf(pin_str, sizeof(pin_str), "%d", g->sysfs_pins[i]);
            (void)write_small_file(unexp_path, pin_str);
        }
    }
    g->backend = GPIO_BACKEND_NONE;
}

/* ==========================================================================
 * 3. TM1628 DUAL-SCREEN PROTOCOL ENGINE (27x5 MATRIX + 4 SIDE ICONS)
 * ========================================================================== */
static void tm1628_write_cmd_byte(athena_gpio_t *g, uint8_t cmd) {
    for (int i = 0; i < 8; i++) {
        athena_gpio_clock_bit(g, (cmd >> i) & 0x01);
    }
}

static void tm1628_write_data_byte(athena_gpio_t *g, uint8_t val, int fill_zero_bits) {
    for (int i = 0; i < 5; i++) {
        athena_gpio_clock_bit(g, (val >> i) & 0x01);
    }
    if (fill_zero_bits) {
        for (int i = 0; i < 6; i++) {
            athena_gpio_clock_bit(g, 0);
        }
    }
}

static void tm1628_unit_tx(athena_gpio_t *g, int stb_idx, uint8_t cmd, const uint8_t *vals, size_t nvals) {
    if (nvals > 14)
        nvals = 14;
    athena_gpio_set_pin(g, stb_idx, 0);
    tm1628_write_cmd_byte(g, cmd);
    for (size_t i = 0; i < nvals; i++) {
        tm1628_write_data_byte(g, vals[i], (i & 1U) != 0);
    }
    athena_gpio_set_pin(g, stb_idx, 1);
}

static void screen_init_mode(athena_gpio_t *g) {
    tm1628_unit_tx(g, IDX_STB_L, TM1628_CMD_DISP_MODE, NULL, 0);
    tm1628_unit_tx(g, IDX_STB_R, TM1628_CMD_DISP_MODE, NULL, 0);
    tm1628_unit_tx(g, IDX_STB_L, TM1628_CMD_DATA_MODE, NULL, 0);
    tm1628_unit_tx(g, IDX_STB_R, TM1628_CMD_DATA_MODE, NULL, 0);
}

static void screen_set_power(athena_gpio_t *g, int on, int level) {
    if (level < 0) level = 0;
    if (level > 7) level = 7;
    uint8_t cmd = on ? (uint8_t)(TM1628_CMD_CTRL_ON | (level & 0x07)) : TM1628_CMD_CTRL_OFF;
    tm1628_unit_tx(g, IDX_STB_L, cmd, NULL, 0);
    tm1628_unit_tx(g, IDX_STB_R, cmd, NULL, 0);
}

static void screen_flush_27x5(athena_gpio_t *g, const uint8_t cols27[27], uint8_t status_icons) {
    uint8_t right14[14];
    memcpy(right14, &cols27[14], 13);
    right14[13] = status_icons & 0x0F;
    tm1628_unit_tx(g, IDX_STB_L, TM1628_CMD_ADDR_ZERO, cols27, 14);
    tm1628_unit_tx(g, IDX_STB_R, TM1628_CMD_ADDR_ZERO, right14, 14);
}

/* ==========================================================================
 * 4. EXTENDED 5-ROW PIXEL FONT DICTIONARY (A-Z, 0-9, %, |, SYMBOLS, ℃)
 * ========================================================================== */
typedef struct {
    uint32_t cp;
    uint8_t len;
    uint8_t cols[10];
} glyph_t;

static const glyph_t g_font[] = {
    {'A', 5, {0x1E, 0x09, 0x09, 0x1E, 0x00}},
    {'B', 5, {0x1F, 0x15, 0x15, 0x0E, 0x00}},
    {'C', 5, {0x0E, 0x11, 0x11, 0x11, 0x00}},
    {'D', 5, {0x1F, 0x11, 0x11, 0x0E, 0x00}},
    {'E', 5, {0x1F, 0x15, 0x15, 0x15, 0x00}},
    {'F', 5, {0x1F, 0x05, 0x05, 0x05, 0x00}},
    {'G', 5, {0x1F, 0x11, 0x15, 0x1D, 0x00}},
    {'H', 5, {0x1F, 0x04, 0x04, 0x1F, 0x00}},
    {'I', 4, {0x11, 0x1F, 0x11, 0x00}},
    {'J', 4, {0x10, 0x10, 0x0F, 0x00}},
    {'K', 5, {0x1F, 0x04, 0x0A, 0x11, 0x00}},
    {'L', 5, {0x1F, 0x10, 0x10, 0x10, 0x00}},
    {'M', 6, {0x1F, 0x01, 0x1E, 0x01, 0x1F, 0x00}},
    {'N', 6, {0x1F, 0x02, 0x04, 0x08, 0x1F, 0x00}},
    {'O', 5, {0x1F, 0x11, 0x11, 0x1F, 0x00}},
    {'P', 5, {0x1F, 0x05, 0x05, 0x07, 0x00}},
    {'Q', 5, {0x0F, 0x09, 0x09, 0x1F, 0x00}},
    {'R', 5, {0x1F, 0x05, 0x0D, 0x12, 0x00}},
    {'S', 5, {0x12, 0x15, 0x15, 0x09, 0x00}},
    {'T', 6, {0x01, 0x01, 0x1F, 0x01, 0x01, 0x00}},
    {'U', 5, {0x1F, 0x10, 0x10, 0x1F, 0x00}},
    {'V', 5, {0x0F, 0x10, 0x10, 0x0F, 0x00}},
    {'W', 6, {0x07, 0x18, 0x07, 0x18, 0x07, 0x00}},
    {'X', 6, {0x11, 0x0A, 0x04, 0x0A, 0x11, 0x00}},
    {'Y', 6, {0x01, 0x02, 0x1C, 0x02, 0x01, 0x00}},
    {'Z', 6, {0x11, 0x19, 0x15, 0x13, 0x11, 0x00}},
    {'0', 4, {0x1F, 0x11, 0x1F, 0x00}},
    {'1', 4, {0x12, 0x1F, 0x10, 0x00}},
    {'2', 4, {0x1D, 0x15, 0x17, 0x00}},
    {'3', 4, {0x15, 0x15, 0x1F, 0x00}},
    {'4', 4, {0x07, 0x04, 0x1F, 0x00}},
    {'5', 4, {0x17, 0x15, 0x1D, 0x00}},
    {'6', 4, {0x1F, 0x15, 0x1D, 0x00}},
    {'7', 4, {0x01, 0x01, 0x1F, 0x00}},
    {'8', 4, {0x1F, 0x15, 0x1F, 0x00}},
    {'9', 4, {0x17, 0x15, 0x1F, 0x00}},
    {' ', 1, {0x00}},
    {'.', 2, {0x10, 0x00}},
    {',', 2, {0x18, 0x00}},
    {'-', 3, {0x04, 0x04, 0x00}},
    {'_', 4, {0x10, 0x10, 0x10, 0x00}},
    {'+', 4, {0x04, 0x0E, 0x04, 0x00}},
    {'*', 6, {0x15, 0x0E, 0x1F, 0x0E, 0x15, 0x00}},
    {'/', 6, {0x10, 0x08, 0x04, 0x02, 0x01, 0x00}},
    {'|', 2, {0x1F, 0x00}},
    {'=', 6, {0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x00}},
    {':', 2, {0x0A, 0x00}},
    {'%', 6, {0x13, 0x0B, 0x04, 0x1A, 0x19, 0x00}},
    {'!', 2, {0x17, 0x00}},
    {'?', 4, {0x01, 0x15, 0x03, 0x00}},
    {'(', 3, {0x0E, 0x11, 0x00}},
    {')', 3, {0x11, 0x0E, 0x00}},
    {'<', 4, {0x04, 0x0A, 0x11, 0x00}},
    {'>', 4, {0x11, 0x0A, 0x04, 0x00}},
    {0x00B0, 4, {0x07, 0x05, 0x07, 0x00}}, /* ° */
    {0xFF1A, 2, {0x0A, 0x00}},             /* ： */
    {0x2103, 9, {0x07, 0x05, 0x07, 0x00, 0x0E, 0x11, 0x11, 0x11, 0x00}}, /* ℃ */
};

static const glyph_t *lookup_glyph(uint32_t cp) {
    if (cp >= 'a' && cp <= 'z')
        cp = cp - 'a' + 'A';
    /* Map common Vietnamese accented vowels to clean uppercase ASCII for 5-row matrix */
    switch (cp) {
        case 0x00C0: case 0x00C1: case 0x00C2: case 0x00C3: case 0x0102:
        case 0x00E0: case 0x00E1: case 0x00E2: case 0x00E3: case 0x0103:
        case 0x1EA0: case 0x1EA1: case 0x1EA2: case 0x1EA3: case 0x1EA4:
        case 0x1EA5: case 0x1EA6: case 0x1EA7: case 0x1EA8: case 0x1EA9:
        case 0x1EAA: case 0x1EAB: case 0x1EAC: case 0x1EAD: case 0x1EAE:
        case 0x1EAF: case 0x1EB0: case 0x1EB1: case 0x1EB2: case 0x1EB3:
        case 0x1EB4: case 0x1EB5: case 0x1EB6: case 0x1EB7:
            cp = 'A'; break;
        case 0x0110: case 0x0111:
            cp = 'D'; break;
        case 0x00C8: case 0x00C9: case 0x00CA: case 0x00E8: case 0x00E9: case 0x00EA:
        case 0x1EB8: case 0x1EB9: case 0x1EBA: case 0x1EBB: case 0x1EBC: case 0x1EBD:
        case 0x1EBE: case 0x1EBF: case 0x1EC0: case 0x1EC1: case 0x1EC2: case 0x1EC3:
        case 0x1EC4: case 0x1EC5: case 0x1EC6: case 0x1EC7:
            cp = 'E'; break;
        case 0x00CC: case 0x00CD: case 0x0128: case 0x00EC: case 0x00ED: case 0x0129:
        case 0x1EC8: case 0x1EC9: case 0x1ECA: case 0x1ECB:
            cp = 'I'; break;
        case 0x00D2: case 0x00D3: case 0x00D4: case 0x00D5: case 0x01A0:
        case 0x00F2: case 0x00F3: case 0x00F4: case 0x00F5: case 0x01A1:
        case 0x1ECC: case 0x1ECD: case 0x1ECE: case 0x1ECF: case 0x1ED0:
        case 0x1ED1: case 0x1ED2: case 0x1ED3: case 0x1ED4: case 0x1ED5:
        case 0x1ED6: case 0x1ED7: case 0x1ED8: case 0x1ED9: case 0x1EDA:
        case 0x1EDB: case 0x1EDC: case 0x1EDD: case 0x1EDE: case 0x1EDF:
        case 0x1EE0: case 0x1EE1: case 0x1EE2: case 0x1EE3:
            cp = 'O'; break;
        case 0x00D9: case 0x00DA: case 0x0168: case 0x01AF:
        case 0x00F9: case 0x00FA: case 0x0169: case 0x01B0:
        case 0x1EE4: case 0x1EE5: case 0x1EE6: case 0x1EE7: case 0x1EE8:
        case 0x1EE9: case 0x1EEA: case 0x1EEB: case 0x1EEC: case 0x1EED:
        case 0x1EEE: case 0x1EEF: case 0x1EF0: case 0x1EF1:
            cp = 'U'; break;
        case 0x00DD: case 0x00FD: case 0x1EF2: case 0x1EF3: case 0x1EF4:
        case 0x1EF5: case 0x1EF6: case 0x1EF7: case 0x1EF8: case 0x1EF9:
            cp = 'Y'; break;
        default:
            break;
    }

    for (size_t i = 0; i < sizeof(g_font) / sizeof(g_font[0]); i++) {
        if (g_font[i].cp == cp)
            return &g_font[i];
    }
    return NULL;
}

static uint32_t utf8_next(const char **p) {
    const unsigned char *s = (const unsigned char *)*p;
    if (!*s)
        return 0;
    uint32_t cp;
    if (s[0] < 0x80) {
        cp = s[0];
        *p += 1;
    } else if ((s[0] & 0xE0) == 0xC0 && (s[1] & 0xC0) == 0x80) {
        cp = ((uint32_t)(s[0] & 0x1F) << 6) | (s[1] & 0x3F);
        *p += 2;
    } else if ((s[0] & 0xF0) == 0xE0 && (s[1] & 0xC0) == 0x80 && (s[2] & 0xC0) == 0x80) {
        cp = ((uint32_t)(s[0] & 0x0F) << 12) | ((uint32_t)(s[1] & 0x3F) << 6) | (s[2] & 0x3F);
        *p += 3;
    } else if ((s[0] & 0xF8) == 0xF0 && (s[1] & 0xC0) == 0x80 && (s[2] & 0xC0) == 0x80 && (s[3] & 0xC0) == 0x80) {
        cp = ((uint32_t)(s[0] & 0x07) << 18) | ((uint32_t)(s[1] & 0x3F) << 12) | ((uint32_t)(s[2] & 0x3F) << 6) | (s[3] & 0x3F);
        *p += 4;
    } else {
        cp = s[0];
        *p += 1;
    }
    return cp;
}

static size_t render_text_columns(const char *str, uint8_t *out, size_t max_cols) {
    size_t n = 0;
    const char *p = str;
    while (*p && n < max_cols) {
        if (*p == '\r' || *p == '\n' || *p == '\t') {
            p++;
            continue;
        }
        uint32_t cp = utf8_next(&p);
        const glyph_t *gl = lookup_glyph(cp);
        if (!gl)
            continue;
        if (n + gl->len > max_cols)
            break;
        memcpy(&out[n], gl->cols, gl->len);
        n += gl->len;
    }
    return n;
}

/* ==========================================================================
 * 5. LIVE TELEMETRY, VIETNAMESE LUNAR CALENDAR & FRONT RGB LED BAR SYNC
 * ========================================================================== */
typedef struct {
    uint64_t prev_rx;
    uint64_t prev_tx;
    struct timespec prev_ts;
    uint64_t rx_bps;
    uint64_t tx_bps;
    int wan_online;
    int mesh_searching;
    int mesh_active;
    char mesh_label[64];
    int rgb_blink_phase;
} live_telemetry_t;

/* Exact Vietnamese Lunar Calendar table (UTC+7) for 2024..2038:
 * Encodes Tet (1/1 Lunar) Julian Day offset from 2024-01-01, leap month (0..12),
 * and 13-bit month length mask (1 = 30 days, 0 = 29 days, bit 0 = month 1).
 */
typedef struct {
    int year;
    int tet_month;
    int tet_day;
    int leap_month;   /* 0 if none, else 1..12 (leap occurs after leap_month) */
    uint16_t mask13;  /* bit i (0..12): 1 => 30 days, 0 => 29 days */
} vn_lunar_year_t;

static const vn_lunar_year_t g_vn_lunar[] = {
    {2024, 2, 10, 0, 0x06D2}, /* Giap Thin (UTC+7 Ho Ngoc Duc) */
    {2025, 1, 29, 6, 0x0EA5}, /* At Ty (nhuan thang 6) */
    {2026, 2, 17, 0, 0x0725}, /* Binh Ngo */
    {2027, 2,  6, 0, 0x064B}, /* Dinh Mui */
    {2028, 1, 26, 5, 0x0C97}, /* Mau Than (nhuan thang 5) */
    {2029, 2, 13, 0, 0x04AB}, /* Ky Dau */
    {2030, 2,  2, 0, 0x055B}, /* Canh Tuat */
    {2031, 1, 23, 3, 0x0ADA}, /* Tan Hoi (nhuan thang 3) */
    {2032, 2, 11, 0, 0x0B6A}, /* Nham Ty */
    {2033, 1, 31, 11,0x1752}, /* Quy Suu (nhuan thang 11) */
    {2034, 2, 19, 0, 0x0B92}, /* Giap Dan */
    {2035, 2,  8, 0, 0x0B25}, /* At Mao */
    {2036, 1, 28, 6, 0x1A4B}, /* Binh Thin (nhuan thang 6) */
};

static long civil_to_days(int y, int m, int d) {
    y -= (m <= 2);
    const int era = (y >= 0 ? y : y - 399) / 400;
    const unsigned yoe = (unsigned)(y - era * 400);
    const unsigned doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
    const unsigned doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return (long)era * 146097L + (long)doe - 719468L;
}

static void format_vn_lunar(const struct tm *lt, char *out, size_t out_sz) {
    int y = lt->tm_year + 1900;
    int m = lt->tm_mon + 1;
    int d = lt->tm_mday;
    long cur_days = civil_to_days(y, m, d);

    const vn_lunar_year_t *ly = NULL;
    long tet_days = 0;
    for (int i = (int)(sizeof(g_vn_lunar) / sizeof(g_vn_lunar[0])) - 1; i >= 0; i--) {
        long td = civil_to_days(g_vn_lunar[i].year, g_vn_lunar[i].tet_month, g_vn_lunar[i].tet_day);
        if (cur_days >= td) {
            ly = &g_vn_lunar[i];
            tet_days = td;
            break;
        }
    }
    if (!ly) {
        snprintf(out, out_sz, "%02d-%02d", d, m);
        return;
    }

    int rem = (int)(cur_days - tet_days);
    int total_months = (ly->leap_month > 0) ? 13 : 12;
    int lmonth = 1, lday = 1;
    for (int idx = 0; idx < total_months; idx++) {
        int mdays = ((ly->mask13 >> idx) & 1) ? 30 : 29;
        if (rem < mdays) {
            lday = rem + 1;
            if (ly->leap_month > 0 && idx >= ly->leap_month)
                lmonth = idx;
            else
                lmonth = idx + 1;
            break;
        }
        rem -= mdays;
    }
    snprintf(out, out_sz, "%02d/%02d AL", lday, lmonth);
}

static void sample_network_and_mesh(live_telemetry_t *t) {
    const char *proc_net = getenv("ATHENA_PROC_NET_DEV");
    if (!proc_net || !*proc_net)
        proc_net = "/proc/net/dev";

    FILE *fp = fopen(proc_net, "r");
    uint64_t sum_rx = 0, sum_tx = 0;
    int found_wan_dev = 0;
    if (fp) {
        char line[512];
        int lineno = 0;
        while (fgets(line, sizeof(line), fp)) {
            if (++lineno <= 2)
                continue;
            char *colon = strchr(line, ':');
            if (!colon)
                continue;
            *colon = '\0';
            char *ifname = line;
            while (*ifname == ' ' || *ifname == '\t')
                ifname++;
            /* Sum WAN / WWAN / 5G / USB / Mesh STA interfaces; skip loopback & pure LAN bridge/ports */
            int is_wan = 0;
            if (strncmp(ifname, "wwan", 4) == 0 || strncmp(ifname, "rmnet", 5) == 0 ||
                strncmp(ifname, "usb", 3) == 0 || strncmp(ifname, "eth1", 4) == 0 ||
                strncmp(ifname, "wan", 3) == 0 || strncmp(ifname, "pppoe", 5) == 0 ||
                strncmp(ifname, "ccmni", 5) == 0 || strncmp(ifname, "mhi", 3) == 0 ||
                strstr(ifname, "sta") != NULL) {
                is_wan = 1;
            }
            if (!is_wan)
                continue;

            unsigned long long rx_b = 0, tx_b = 0, dummy = 0;
            if (sscanf(colon + 1, "%llu %llu %llu %llu %llu %llu %llu %llu %llu",
                       &rx_b, &dummy, &dummy, &dummy, &dummy, &dummy, &dummy, &dummy, &tx_b) == 9) {
                sum_rx += rx_b;
                sum_tx += tx_b;
                if (rx_b > 0 || tx_b > 0)
                    found_wan_dev = 1;
            }
        }
        fclose(fp);
    }

    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    if (t->prev_ts.tv_sec != 0) {
        double dt = (double)(now.tv_sec - t->prev_ts.tv_sec) +
                    (double)(now.tv_nsec - t->prev_ts.tv_nsec) / 1e9;
        if (dt >= 0.25) {
            t->rx_bps = (sum_rx >= t->prev_rx) ? (uint64_t)((double)(sum_rx - t->prev_rx) / dt) : 0;
            t->tx_bps = (sum_tx >= t->prev_tx) ? (uint64_t)((double)(sum_tx - t->prev_tx) / dt) : 0;
            t->prev_rx = sum_rx;
            t->prev_tx = sum_tx;
            t->prev_ts = now;
        }
    } else {
        t->prev_rx = sum_rx;
        t->prev_tx = sum_tx;
        t->prev_ts = now;
    }

    /* Check default route in /proc/net/route for true WAN connectivity */
    int has_def_route = 0;
    FILE *rfp = fopen("/proc/net/route", "r");
    if (rfp) {
        char rline[256], iface[32];
        unsigned int dest = 1;
        while (fgets(rline, sizeof(rline), rfp)) {
            if (sscanf(rline, "%31s %x", iface, &dest) == 2 && dest == 0) {
                has_def_route = 1;
                break;
            }
        }
        fclose(rfp);
    }
    t->wan_online = (has_def_route || found_wan_dev) ? 1 : 0;

    /* Read Auto-Mesh status from /tmp/auto_mesh_status.json & /tmp/mesh_node_info.json */
    t->mesh_searching = 0;
    t->mesh_active = 0;
    char mbuf[1024];
    const char *mesh_status_path = getenv("ATHENA_MESH_STATUS_FILE");
    if (!mesh_status_path || !*mesh_status_path)
        mesh_status_path = "/tmp/auto_mesh_status.json";

    if (read_small_file(mesh_status_path, mbuf, sizeof(mbuf)) > 0) {
        if (strstr(mbuf, "\"searching\": true") || strstr(mbuf, "\"searching\":true"))
            t->mesh_searching = 1;
        if (strstr(mbuf, "\"role\": \"controller\"") || strstr(mbuf, "\"role\":\"controller\"")) {
            t->mesh_active = 1;
            snprintf(t->mesh_label, sizeof(t->mesh_label), "CHINH");
        } else if (strstr(mbuf, "\"role\": \"node\"") || strstr(mbuf, "\"role\":\"node\"")) {
            t->mesh_active = 1;
            t->wan_online = 1;
            const char *ip_p = strstr(mbuf, "192.168.");
            if (ip_p) {
                const char *dot = strrchr(ip_p, '.');
                int last_oct = dot ? atoi(dot + 1) : 10;
                snprintf(t->mesh_label, sizeof(t->mesh_label), "PHU .%d", last_oct);
            } else {
                snprintf(t->mesh_label, sizeof(t->mesh_label), "PHU MESH");
            }
        }
    }
    if (!t->mesh_active) {
        snprintf(t->mesh_label, sizeof(t->mesh_label), "ROUTER");
    }
}

static void format_rate_short(uint64_t bps, char *buf, size_t sz) {
    /* Convert bytes/sec to human friendly MB/s or KB/s */
    double kb = (double)bps / 1024.0;
    double mb = kb / 1024.0;
    if (mb >= 100.0)
        snprintf(buf, sz, "%.0fMB/S", mb);
    else if (mb >= 1.0)
        snprintf(buf, sz, "%.1fMB/S", mb);
    else if (kb >= 10.0)
        snprintf(buf, sz, "%.0fKB/S", kb);
    else
        snprintf(buf, sz, "0KB/S");
}

static int count_lan_clients(void) {
    int count = 0;
    FILE *fp = fopen("/proc/net/arp", "r");
    if (!fp)
        return 0;
    char line[256];
    int lineno = 0;
    while (fgets(line, sizeof(line), fp)) {
        if (++lineno == 1)
            continue;
        char ip[64], hw[32], flags[32], mac[32], mask[32], dev[32];
        if (sscanf(line, "%63s %31s %31s %31s %31s %31s", ip, hw, flags, mac, mask, dev) == 6) {
            if (strcmp(flags, "0x2") == 0 && strncmp(dev, "br-lan", 6) == 0)
                count++;
        }
    }
    fclose(fp);
    return count;
}

static void set_single_led_color(const char *leds_root, const char *color_kw, int on, int release_trigger) {
    DIR *d = opendir(leds_root);
    if (!d)
        return;
    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        if (ent->d_name[0] == '.')
            continue;
        if (!strstr(ent->d_name, color_kw) || !strstr(ent->d_name, "status"))
            continue;
        char trig_path[512], bri_path[512], max_path[512], max_s[32] = "1";
        snprintf(trig_path, sizeof(trig_path), "%s/%s/trigger", leds_root, ent->d_name);
        snprintf(bri_path, sizeof(bri_path), "%s/%s/brightness", leds_root, ent->d_name);
        snprintf(max_path, sizeof(max_path), "%s/%s/max_brightness", leds_root, ent->d_name);
        if (release_trigger) {
            if (strcmp(color_kw, "green") == 0) {
                (void)write_small_file(trig_path, "default-on");
                (void)write_small_file(bri_path, "1");
            } else {
                (void)write_small_file(bri_path, "0");
            }
            continue;
        }
        (void)write_small_file(trig_path, "none");
        if (on) {
            read_small_file(max_path, max_s, sizeof(max_s));
            int mv = atoi(max_s);
            if (mv <= 0) mv = 1;
            char vbuf[16];
            snprintf(vbuf, sizeof(vbuf), "%d", mv);
            (void)write_small_file(bri_path, vbuf);
        } else {
            (void)write_small_file(bri_path, "0");
        }
    }
    closedir(d);
}

static void update_front_rgb_bar(const char *rgb_mode, int screen_off, live_telemetry_t *t) {
    if (!rgb_mode || !*rgb_mode || strcmp(rgb_mode, "system") == 0)
        return;

    const char *leds_root = getenv("ATHENA_SYSFS_LEDS_DIR");
    if (!leds_root || !*leds_root)
        leds_root = "/sys/class/leds";

    int r = 0, g = 0, b = 0;
    if (!screen_off && strcmp(rgb_mode, "off") != 0) {
        if (strcmp(rgb_mode, "auto") == 0) {
            if (t->mesh_searching) {
                t->rgb_blink_phase = !t->rgb_blink_phase;
                b = t->rgb_blink_phase ? 1 : 0;
            } else if (t->wan_online) {
                /* Cyan when high traffic (> 1 MB/s), calm Green when idle */
                g = 1;
                b = (t->rx_bps + t->tx_bps > 1048576ULL) ? 1 : 0;
            } else {
                r = 1;
            }
        } else if (strcmp(rgb_mode, "green") == 0) {
            g = 1;
        } else if (strcmp(rgb_mode, "blue") == 0) {
            b = 1;
        } else if (strcmp(rgb_mode, "cyan") == 0) {
            g = 1; b = 1;
        } else if (strcmp(rgb_mode, "purple") == 0) {
            r = 1; b = 1;
        } else if (strcmp(rgb_mode, "white") == 0) {
            r = 1; g = 1; b = 1;
        } else if (strcmp(rgb_mode, "red") == 0) {
            r = 1;
        }
    }

    set_single_led_color(leds_root, "red", r, 0);
    set_single_led_color(leds_root, "green", g, 0);
    set_single_led_color(leds_root, "blue", b, 0);
}

static void restore_front_rgb_bar(const char *rgb_mode) {
    if (!rgb_mode || !*rgb_mode || strcmp(rgb_mode, "system") == 0)
        return;
    const char *leds_root = getenv("ATHENA_SYSFS_LEDS_DIR");
    if (!leds_root || !*leds_root)
        leds_root = "/sys/class/leds";
    set_single_led_color(leds_root, "red", 0, 1);
    set_single_led_color(leds_root, "blue", 0, 1);
    set_single_led_color(leds_root, "green", 1, 1);
}

/* ==========================================================================
 * 6. THERMAL, LIVE CACHE & SCHEDULE HELPERS
 * ========================================================================== */
static void build_temp_string(const char *temp_flags, char *out, size_t out_sz) {
    out[0] = '\0';
    size_t pos = 0;
    const char *therm_root = getenv("ATHENA_SYSFS_THERMAL_DIR");
    if (!therm_root || !*therm_root)
        therm_root = "/sys/class/thermal";

    for (int i = 0; i <= 6; i++) {
        char idx_s[4];
        snprintf(idx_s, sizeof(idx_s), "%d", i);
        if (!strstr(temp_flags, idx_s))
            continue;

        char tpath[256], vpath[256], ztype[64], zval[32];
        snprintf(tpath, sizeof(tpath), "%s/thermal_zone%d/type", therm_root, i);
        snprintf(vpath, sizeof(vpath), "%s/thermal_zone%d/temp", therm_root, i);
        if (read_small_file(tpath, ztype, sizeof(ztype)) <= 0 ||
            read_small_file(vpath, zval, sizeof(zval)) <= 0)
            continue;

        char *dash = strstr(ztype, "-thermal");
        if (dash)
            *dash = '\0';
        double c = (double)atoi(zval) / 1000.0;
        int n = snprintf(out + pos, out_sz - pos, "%s:%.0f℃  ", ztype, c);
        if (n > 0 && (size_t)n < out_sz - pos)
            pos += (size_t)n;
    }
    while (pos > 0 && out[pos - 1] == ' ')
        out[--pos] = '\0';
}

static int read_kv_cache(const char *key, char *out, size_t out_sz) {
    const char *cache_file = getenv("ATHENA_LIVE_CACHE_FILE");
    if (!cache_file || !*cache_file)
        cache_file = "/tmp/athena_led_live.cache";
    FILE *fp = fopen(cache_file, "r");
    if (!fp)
        return -1;
    char line[512];
    size_t klen = strlen(key);
    int found = -1;
    while (fgets(line, sizeof(line), fp)) {
        if (strncmp(line, key, klen) == 0 && line[klen] == '=') {
            char *val = line + klen + 1;
            size_t vlen = strlen(val);
            while (vlen > 0 && (val[vlen - 1] == '\n' || val[vlen - 1] == '\r'))
                val[--vlen] = '\0';
            snprintf(out, out_sz, "%s", val);
            found = (out[0] != '\0') ? 0 : -1;
            break;
        }
    }
    fclose(fp);
    return found;
}

static int is_in_night_window(const struct tm *lt, int enable_night, int start_min, int end_min) {
    if (!enable_night || start_min == end_min)
        return 0;
    int cur = lt->tm_hour * 60 + lt->tm_min;
    if (start_min < end_min)
        return (cur >= start_min && cur < end_min);
    return (cur >= start_min || cur < end_min);
}

static int parse_hhmm(const char *s, int def_min) {
    if (!s || !*s)
        return def_min;
    int h = 0, m = 0;
    if (sscanf(s, "%d:%d", &h, &m) == 2 && h >= 0 && h <= 23 && m >= 0 && m <= 59)
        return h * 60 + m;
    if (sscanf(s, "%d", &h) == 1 && h >= 0 && h <= 23)
        return h * 60;
    return def_min;
}

static uint8_t compute_icons(uint8_t base_status, int auto_icons, const char *mode, const live_telemetry_t *t) {
    uint8_t st = base_status;
    if (!auto_icons)
        return st;
    if (strcmp(mode, "time") == 0 || strcmp(mode, "timeBlink") == 0 ||
        strcmp(mode, "date") == 0 || strcmp(mode, "lunar") == 0) {
        st |= ICON_TIME;
    }
    if (t->mesh_active || t->wan_online)
        st |= ICON_MEDAL;
    if (t->tx_bps >= NET_ACTIVE_BPS)
        st |= ICON_UPLOAD;
    if (t->rx_bps >= NET_ACTIVE_BPS)
        st |= ICON_DOWNLOAD;
    return st;
}

/* ==========================================================================
 * 7. DISPLAY RENDERING (STATIC CENTERED OR SMOOTH SCROLLING)
 * ========================================================================== */
static void display_text_for_duration(
    athena_gpio_t *g,
    const char *text,
    int seconds,
    uint8_t base_status,
    int auto_icons,
    const char *mode_name,
    const char *rgb_mode,
    live_telemetry_t *tele
) {
    uint8_t cols[2048];
    size_t ncols = render_text_columns(text, cols, sizeof(cols));
    if (ncols == 0)
        return;

    if (ncols <= 27) {
        uint8_t frame[27];
        memset(frame, 0, sizeof(frame));
        size_t offset = (27 - ncols) / 2;
        memcpy(&frame[offset], cols, ncols);

        int steps = seconds * 2; /* 500ms ticks so icons & SIGUSR1 stay responsive */
        if (steps < 1) steps = 1;
        for (int s = 0; s < steps && !g_stop && !g_usr1_toggle; s++) {
            if ((s % 2) == 0) {
                sample_network_and_mesh(tele);
                update_front_rgb_bar(rgb_mode, 0, tele);
            }
            uint8_t icons = compute_icons(base_status, auto_icons, mode_name, tele);
            screen_flush_27x5(g, frame, icons);
            usleep(500000);
        }
    } else {
        /* Smooth marquee right-to-left (115 ms per column) */
        size_t start = 0;
        int tick = 0;
        for (size_t i = 1; i <= ncols && !g_stop && !g_usr1_toggle; i++) {
            uint8_t frame[27];
            memset(frame, 0, sizeof(frame));
            if (i > 27)
                start++;
            size_t slice = i - start;
            if (slice > 27)
                slice = 27;
            /* Enter from right edge smoothly when i < 27 */
            if (i < 27)
                memcpy(&frame[27 - slice], &cols[start], slice);
            else
                memcpy(frame, &cols[start], slice);

            if ((tick++ % 8) == 0) {
                sample_network_and_mesh(tele);
                update_front_rgb_bar(rgb_mode, 0, tele);
            }
            uint8_t icons = compute_icons(base_status, auto_icons, mode_name, tele);
            screen_flush_27x5(g, frame, icons);
            usleep(115000);
        }
        /* Brief pause at end of marquee */
        for (int p = 0; p < 4 && !g_stop && !g_usr1_toggle; p++)
            usleep(200000);
    }
}

/* ==========================================================================
 * 8. BOARD GUARD & CLI ENTRYPOINT
 * ========================================================================== */
static int verify_athena_board(int force_board) {
    if (force_board)
        return 1;
    const char *board_file = getenv("ATHENA_BOARD_FILE");
    if (!board_file || !*board_file)
        board_file = "/tmp/sysinfo/board_name";
    char bname[128];
    if (read_small_file(board_file, bname, sizeof(bname)) > 0) {
        if (strstr(bname, "re-cs-02"))
            return 1;
        return 0;
    }
    /* Fallback check on /tmp/sysinfo/model */
    if (read_small_file("/tmp/sysinfo/model", bname, sizeof(bname)) > 0) {
        if (strstr(bname, "RE-CS-02") || strstr(bname, "Athena"))
            return 1;
    }
    return 0;
}

int main(int argc, char **argv) {
    const char *status_str   = "";
    int seconds              = 5;
    int light_level          = 5;
    const char *options_str  = "timeBlink date lunar netSpeed string";
    const char *custom_val   = "DOAN DUY";
    const char *url_str      = "";
    const char *temp_flag    = "4";
    int auto_icons           = 1;
    const char *rgb_mode     = "auto";
    int night_mode           = 0;
    const char *night_start  = "23:00";
    const char *night_end    = "06:00";
    int night_level          = -1; /* -1 = turn screen completely OFF at night, 0..7 = dim */
    int force_board          = 0;
    int one_shot_cycles      = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-status") == 0 && i + 1 < argc) status_str = argv[++i];
        else if (strcmp(argv[i], "-seconds") == 0 && i + 1 < argc) seconds = atoi(argv[++i]);
        else if (strcmp(argv[i], "-lightLevel") == 0 && i + 1 < argc) light_level = atoi(argv[++i]);
        else if (strcmp(argv[i], "-option") == 0 && i + 1 < argc) options_str = argv[++i];
        else if (strcmp(argv[i], "-value") == 0 && i + 1 < argc) custom_val = argv[++i];
        else if (strcmp(argv[i], "-url") == 0 && i + 1 < argc) url_str = argv[++i];
        else if (strcmp(argv[i], "-tempFlag") == 0 && i + 1 < argc) temp_flag = argv[++i];
        else if (strcmp(argv[i], "-autoIcons") == 0 && i + 1 < argc) auto_icons = atoi(argv[++i]);
        else if (strcmp(argv[i], "-rgbMode") == 0 && i + 1 < argc) rgb_mode = argv[++i];
        else if (strcmp(argv[i], "-nightMode") == 0 && i + 1 < argc) night_mode = atoi(argv[++i]);
        else if (strcmp(argv[i], "-nightStart") == 0 && i + 1 < argc) night_start = argv[++i];
        else if (strcmp(argv[i], "-nightEnd") == 0 && i + 1 < argc) night_end = argv[++i];
        else if (strcmp(argv[i], "-nightLevel") == 0 && i + 1 < argc) night_level = atoi(argv[++i]);
        else if (strcmp(argv[i], "-forceBoard") == 0 && i + 1 < argc) force_board = atoi(argv[++i]);
        else if (strcmp(argv[i], "-cycles") == 0 && i + 1 < argc) one_shot_cycles = atoi(argv[++i]);
    }
    (void)url_str; /* Fetched asynchronously by /usr/bin/athena-led-collector into /tmp/athena_led_live.cache */

    if (seconds < 1) seconds = 1;
    if (seconds > 60) seconds = 60;
    if (light_level < 0) light_level = 0;
    if (light_level > 7) light_level = 7;

    if (!verify_athena_board(force_board)) {
        fprintf(stderr, "athena-led: Non-Athena board detected; exiting cleanly.\n");
        return 0;
    }

    /* Ensure Vietnam ICT timezone default if TZ unset */
    if (!getenv("TZ")) {
        char sys_cfg[2048];
        if (read_small_file("/etc/config/system", sys_cfg, sizeof(sys_cfg)) > 0 && strstr(sys_cfg, "Ho_Chi_Minh"))
            setenv("TZ", "ICT-7", 1);
    }
    tzset();

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = on_signal;
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGHUP, &sa, NULL);
    sigaction(SIGUSR1, &sa, NULL);

    uint8_t base_status = 0;
    if (strstr(status_str, "time"))     base_status |= ICON_TIME;
    if (strstr(status_str, "medal"))    base_status |= ICON_MEDAL;
    if (strstr(status_str, "upload"))   base_status |= ICON_UPLOAD;
    if (strstr(status_str, "download")) base_status |= ICON_DOWNLOAD;

    athena_gpio_t gpio;
    if (athena_gpio_init(&gpio) != 0) {
        fprintf(stderr, "athena-led: Failed to initialize TLMM GPIO lines.\n");
        return 1;
    }

    screen_init_mode(&gpio);
    screen_set_power(&gpio, 1, light_level);

    int night_start_min = parse_hhmm(night_start, 23 * 60);
    int night_end_min   = parse_hhmm(night_end, 6 * 60);

    /* User BTN_1 manual brightness cycle state: 0 = normal, 1 = dim(1), 2 = off */
    int manual_state = 0;
    int applied_power = 1;
    int applied_level = light_level;

    live_telemetry_t tele;
    memset(&tele, 0, sizeof(tele));
    sample_network_and_mesh(&tele);

    /* Tokenize display modes once */
    char modes_buf[256];
    snprintf(modes_buf, sizeof(modes_buf), "%s", options_str);
    char *modes[16];
    int nmodes = 0;
    char *saveptr = NULL;
    for (char *tok = strtok_r(modes_buf, " \t,", &saveptr); tok && nmodes < 16; tok = strtok_r(NULL, " \t,", &saveptr)) {
        modes[nmodes++] = tok;
    }
    if (nmodes == 0) {
        modes[0] = (char *)"timeBlink";
        nmodes = 1;
    }

    /* Persist live state for LuCI status badge */
    (void)write_state_file("/tmp/athena_led.state", "NORMAL");

    int blink_colon = 0;
    int loops_done = 0;

    while (!g_stop) {
        if (g_usr1_toggle) {
            g_usr1_toggle = 0;
            manual_state = (manual_state + 1) % 3;
            const char *st_lbl = (manual_state == 0) ? "NORMAL" : (manual_state == 1 ? "DIM" : "OFF");
            (void)write_state_file("/tmp/athena_led.state", st_lbl);
        }

        time_t now_epoch = time(NULL);
        struct tm lt;
        localtime_r(&now_epoch, &lt);

        int in_night = is_in_night_window(&lt, night_mode, night_start_min, night_end_min);
        int target_on = 1;
        int target_lvl = light_level;

        if (manual_state == 2) {
            target_on = 0;
        } else if (manual_state == 1) {
            target_on = 1;
            target_lvl = 1;
        } else if (in_night) {
            if (night_level < 0) {
                target_on = 0;
            } else {
                target_on = 1;
                target_lvl = night_level;
            }
        }

        if (target_on != applied_power || (target_on && target_lvl != applied_level)) {
            uint8_t blank[27] = {0};
            if (!target_on)
                screen_flush_27x5(&gpio, blank, 0);
            screen_set_power(&gpio, target_on, target_lvl);
            applied_power = target_on;
            applied_level = target_lvl;
        }

        if (!target_on) {
            sample_network_and_mesh(&tele);
            update_front_rgb_bar(rgb_mode, 1, &tele);
            for (int w = 0; w < 10 && !g_stop && !g_usr1_toggle; w++)
                usleep(100000);
            if (one_shot_cycles > 0 && ++loops_done >= one_shot_cycles)
                break;
            continue;
        }

        for (int m = 0; m < nmodes && !g_stop && !g_usr1_toggle; m++) {
            const char *opt = modes[m];
            now_epoch = time(NULL);
            localtime_r(&now_epoch, &lt);
            sample_network_and_mesh(&tele);
            update_front_rgb_bar(rgb_mode, 0, &tele);

            if (strcmp(opt, "timeBlink") == 0) {
                for (int s = 0; s < seconds && !g_stop && !g_usr1_toggle; s++) {
                    now_epoch = time(NULL);
                    localtime_r(&now_epoch, &lt);
                    sample_network_and_mesh(&tele);
                    update_front_rgb_bar(rgb_mode, 0, &tele);

                    char tbuf[16];
                    if (blink_colon)
                        snprintf(tbuf, sizeof(tbuf), "%02d  %02d", lt.tm_hour, lt.tm_min);
                    else
                        snprintf(tbuf, sizeof(tbuf), "%02d:%02d", lt.tm_hour, lt.tm_min);
                    blink_colon = !blink_colon;

                    uint8_t cols[32], frame[27] = {0};
                    size_t nc = render_text_columns(tbuf, cols, sizeof(cols));
                    if (nc <= 27)
                        memcpy(&frame[(27 - nc) / 2], cols, nc);
                    uint8_t icons = compute_icons(base_status, auto_icons, opt, &tele);
                    screen_flush_27x5(&gpio, frame, icons);
                    usleep(1000000);
                }
            } else if (strcmp(opt, "time") == 0) {
                char tbuf[16];
                snprintf(tbuf, sizeof(tbuf), "%02d:%02d", lt.tm_hour, lt.tm_min);
                display_text_for_duration(&gpio, tbuf, seconds, base_status, auto_icons, opt, rgb_mode, &tele);
            } else if (strcmp(opt, "date") == 0) {
                /* Standard Vietnamese DD-MM format */
                char dbuf[16];
                snprintf(dbuf, sizeof(dbuf), "%02d-%02d", lt.tm_mday, lt.tm_mon + 1);
                display_text_for_duration(&gpio, dbuf, seconds, base_status, auto_icons, opt, rgb_mode, &tele);
            } else if (strcmp(opt, "lunar") == 0) {
                char lbuf[32];
                format_vn_lunar(&lt, lbuf, sizeof(lbuf));
                display_text_for_duration(&gpio, lbuf, seconds, base_status, auto_icons, opt, rgb_mode, &tele);
            } else if (strcmp(opt, "netSpeed") == 0) {
                /* Live real-time refresh every 1s during interval */
                for (int s = 0; s < seconds && !g_stop && !g_usr1_toggle; s++) {
                    sample_network_and_mesh(&tele);
                    update_front_rgb_bar(rgb_mode, 0, &tele);
                    char rx_s[24], sbuf[48];
                    format_rate_short(tele.rx_bps, rx_s, sizeof(rx_s));
                    snprintf(sbuf, sizeof(sbuf), "%s", rx_s);

                    uint8_t cols[64], frame[27] = {0};
                    size_t nc = render_text_columns(sbuf, cols, sizeof(cols));
                    if (nc > 27) nc = 27;
                    memcpy(&frame[(27 - nc) / 2], cols, nc);
                    uint8_t icons = compute_icons(base_status, auto_icons, opt, &tele);
                    screen_flush_27x5(&gpio, frame, icons);
                    usleep(1000000);
                }
            } else if (strcmp(opt, "modem5g") == 0) {
                char mbuf[256];
                if (read_kv_cache("MODEM5G", mbuf, sizeof(mbuf)) == 0)
                    display_text_for_duration(&gpio, mbuf, seconds, base_status, auto_icons, opt, rgb_mode, &tele);
                else if (tele.wan_online)
                    display_text_for_duration(&gpio, "5G ONLINE", seconds, base_status, auto_icons, opt, rgb_mode, &tele);
            } else if (strcmp(opt, "meshInfo") == 0) {
                int clis = count_lan_clients();
                char minfo[96];
                snprintf(minfo, sizeof(minfo), "%s | %d TB", tele.mesh_label, clis);
                display_text_for_duration(&gpio, minfo, seconds, base_status, auto_icons, opt, rgb_mode, &tele);
            } else if (strcmp(opt, "weatherVN") == 0) {
                char wbuf[256];
                if (read_kv_cache("WEATHER", wbuf, sizeof(wbuf)) == 0)
                    display_text_for_duration(&gpio, wbuf, seconds, base_status, auto_icons, opt, rgb_mode, &tele);
            } else if (strcmp(opt, "temp") == 0) {
                char tstr[256];
                build_temp_string(temp_flag, tstr, sizeof(tstr));
                if (tstr[0] != '\0')
                    display_text_for_duration(&gpio, tstr, seconds, base_status, auto_icons, opt, rgb_mode, &tele);
            } else if (strcmp(opt, "string") == 0) {
                if (custom_val && *custom_val)
                    display_text_for_duration(&gpio, custom_val, seconds, base_status, auto_icons, opt, rgb_mode, &tele);
            } else if (strcmp(opt, "getByUrl") == 0) {
                char ubuf[512];
                if (read_kv_cache("URLTEXT", ubuf, sizeof(ubuf)) == 0)
                    display_text_for_duration(&gpio, ubuf, seconds, base_status, auto_icons, opt, rgb_mode, &tele);
            }
        }

        if (one_shot_cycles > 0 && ++loops_done >= one_shot_cycles)
            break;
    }

    /* Clean shutdown: clear matrix, power off TM1628, release GPIO & restore RGB */
    uint8_t zero27[27] = {0};
    screen_flush_27x5(&gpio, zero27, 0);
    screen_set_power(&gpio, 0, 0);
    athena_gpio_close(&gpio);
    restore_front_rgb_bar(rgb_mode);
    unlink("/tmp/athena_led.state");
    return 0;
}
// [/VERIFIED-GOLDEN]
