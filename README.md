# Duydoan-24.10 for JDCloud RE-CS-02 (Athena AX6600) Full Power Edition

<div align="center">

[![Distro Version](https://img.shields.io/badge/Duydoan-24.10%20LTS%20(Pinned)-007ec6.svg?style=for-the-badge&logo=openwrt)](https://github.com/Doanduy09/JDCloud-RE-CS-02)
[![Hardware Target](https://img.shields.io/badge/Target-JDCloud%20RE--CS--02-ff69b4.svg?style=for-the-badge&logo=qualcomm)](https://github.com/Doanduy09/JDCloud-RE-CS-02)
[![NSS Acceleration](https://img.shields.io/badge/NSS%20Offload-v12.5%20Hardware%20Max-brightgreen.svg?style=for-the-badge)](https://github.com/Doanduy09/JDCloud-RE-CS-02)
[![Storage](https://img.shields.io/badge/eMMC%20Storage-64GB%2F128GB%20F2FS%20Auto-orange.svg?style=for-the-badge)](https://github.com/Doanduy09/JDCloud-RE-CS-02)
[![Daily Build](https://img.shields.io/badge/Auto%20Build-Daily%2007%3A00%20ICT-success.svg?style=for-the-badge&logo=githubactions)](https://github.com/Doanduy09/JDCloud-RE-CS-02/actions)
[![Maintained By](https://img.shields.io/badge/Author-Doanduy09-blue.svg?style=for-the-badge&logo=github)](https://github.com/Doanduy09)

**Bản phân phối hệ điều hành Duydoan-24.10 chuyên dụng khai phóng 100% năng lực phần cứng của router JDCloud RE-CS-02 (Athena AX6600).**  
*Được duy trì và phát triển bởi Anh Duy (DOANDUY).*

</div>

---

## 🔒 NGUYÊN TẮC CỐT LÕI: KHÓA CỨNG NỀN TẢNG 24.10 (IMMUTABLE BASE POLICY)

> [!IMPORTANT]
> **Cam Kết Bất Biến Về Phiên Bản (Strict Version Pinning):**
> Kho lưu trữ này được thiết kế và cố định **DUY NHẤT TRÊN NỀN TẢNG BẢN 24.10 (Kernel 6.6 LTS)**.
> - **Tuyệt đối không nâng cấp hoặc thay đổi nhánh gốc (base branch)** sang 25.x, master hay các bản snapshot không tương thích làm mất tính ổn định của hệ thống driver Qualcomm NSS.
> - **Mọi bản cập nhật trong tương lai chỉ tập trung tối ưu hóa các thành phần sau:**
>   1. Tinh chỉnh driver tăng tốc phần cứng Qualcomm NSS 12.5 (`qca-nss-drv`, `qca-nss-ecm`, `qca-nss-dp`).
>   2. Mở rộng hỗ trợ modem di động 4G/5G (`ARPHRD_RAWIP`, MBIM, QMI, XMM, ModemManager, Quectel, Fibocom).
>   3. Tối ưu hóa phân vùng lưu trữ eMMC F2FS (`athena_storage`), Docker, Optware.
>   4. Nâng cấp hiệu năng Wi-Fi 6 Tri-Band 160MHz (`ath11k`, `QCN9074`, caldata trích xuất `0:ART`).
>   5. Quản lý màn hình LED Athena (`luci-app-athena-led`) và các tiện ích mạng chuyên sâu.

---

## 🚀 CÁC TÍNH NĂNG VÀ ĐỘT PHÁ CÔNG NGHỆ CHÍNH

### 1. Qualcomm NSS 12.5 Hardware Acceleration (Tăng Tốc Phần Cứng Cực Hạn)
- **Zero-Bottleneck Architecture:** Đã gỡ bỏ triệt để `luci-app-sqm`, `sqm-scripts` và các qdisc can thiệp phần mềm để luồng dữ liệu đạt tốc độ tối đa không độ trễ.
- **Tăng Tốc Modem Di Động Toàn Diện (Cellular Modem Hardware Offload):**
  - Tích hợp cờ đặc biệt `ECM_INTERFACE_RAWIP_ENABLE=y` cho phép NSS can thiệp tăng tốc trực tiếp các giao thức `ARPHRD_RAWIP` của modem di động.
  - Tương thích tối đa với: **MBIM**, **QMI (RAW-IP)**, **XMM**, **ModemManager**, **ECM**, **RNDIS**, **CDC-NCM**.
- **Tăng tốc mạng toàn diện:** Hỗ trợ PPPoE offload, Bridge offload, VLAN Manager, SKB Recycler, và bypass phần mềm firewall để truyền trực tiếp vào NSS Engine.

### 2. Tự Động Khởi Tạo & Mở Full Flash eMMC (64GB / 128GB F2FS)
- Tích hợp dịch vụ khởi động tự hành `/etc/init.d/athena_storage` (`START=95`).
- Tự động quét và phát hiện các sector chưa phân bổ của chip nhớ eMMC vượt ngoài 26 phân vùng gốc của JDCloud.
- Tự động tạo phân vùng an toàn số 27 (`/dev/mmcblk0p27`).
- Định dạng bằng hệ thống tệp tối ưu cho Flash **F2FS** (`AthenaStorage`) và mount vào `/mnt/storage`.
- Tự động tạo liên kết tượng trưng (symlinks):
  - `/opt -> /mnt/storage/opt`
  - `/docker -> /mnt/storage/docker`
- **Bảo toàn dữ liệu 100%:** Toàn bộ cấu hình hệ thống và overlay được bảo toàn nguyên vẹn sau mỗi lần khởi động lại router.

### 3. Tri-Band Wi-Fi 6 AX6600 Đạt Chuẩn Hiệu Năng Cao
- **Băng tần 2.4GHz:** 2x2 MIMO 802.11ax (IPQ6010 tích hợp).
- **Băng tần 5.2GHz (Low-Band):** 2x2 MIMO 802.11ax (IPQ6010 tích hợp).
- **Băng tần 5.8GHz (High-Band):** 4x4 MIMO 802.11ax với độ rộng kênh **160MHz** (chipset chuyên dụng Qualcomm QCN9074).
- Tích hợp caldata trích xuất trực tiếp từ phân vùng gốc `0:ART` (`ipq-wifi-jdcloud_re-cs-02`), đảm bảo công suất phát và khả năng roaming đạt chuẩn nhà sản xuất.

### 4. Màn Hình LED Ma Trận Athena (Athena LED Screen)
- Tích hợp gói ứng dụng `luci-app-athena-led` cho phép quản trị và tùy biến hiển thị tốc độ mạng, đồng hồ, nhiệt độ và trạng thái thiết bị trực tiếp trên màn hình LED ma trận mặt trước của router JDCloud RE-CS-02.

---

## 🛠️ HƯỚNG DẪN TỰ BIÊN DỊCH (BUILD INSTRUCTIONS)

### Biên dịch thủ công trên máy chủ / máy ảo Debian/Ubuntu:

```bash
# 1. Cài đặt các gói phụ thuộc
sudo apt update -y
sudo apt install -y build-essential clang flex bison g++ gawk gcc-multilib g++-multilib   gettext git libncurses-dev libssl-dev python3-distutils rsync unzip zlib1g-dev file wget

# 2. Clone repository của Anh Duy
git clone https://github.com/Doanduy09/JDCloud-RE-CS-02.git
cd JDCloud-RE-CS-02

# 3. Cập nhật và cài đặt feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 4. Nạp cấu hình tối ưu sẵn có cho RE-CS-02
cp jdcloud_re-cs-02-nss.config .config
make defconfig

# 5. Tải mã nguồn các gói và bắt đầu biên dịch
make download -j8
make -j$(nproc) || make -j1 V=s
```

### Biên dịch tự động qua GitHub Actions:
- Workflow **Build Duydoan-24.10 JDCloud RE-CS-02** được thiết lập tự động kích hoạt vào lúc **07:00 sáng mỗi ngày** (Giờ Việt Nam / UTC+7, cron: `0 0 * * *`).
- Có thể kích hoạt thủ công bất kỳ lúc nào từ tab **Actions** -> Chọn workflow -> Bấm **Run workflow**.

---

## 📦 THÔNG TIN FILE FIRMWARE & FLASHING

| Tên File | Chức Năng | Mục Đích Sử Dụng |
| :--- | :--- | :--- |
| `duydoan-24.10-*-jdcloud_re-cs-02-squashfs-factory.bin` | Cài đặt ban đầu | Dùng nạp lần đầu từ U-Boot / Web cứu hộ |
| `duydoan-24.10-*-jdcloud_re-cs-02-squashfs-sysupgrade.bin` | Nâng cấp hệ điều hành | Dùng nâng cấp trực tiếp từ giao diện LuCI / SSH |

---

## 🔍 KIỂM TRA TRẠNG THÁI SAU KHI FLASH

```bash
# Kiểm tra tải trọng và trạng thái nhân tăng tốc phần cứng NSS:
cat /sys/kernel/debug/qca-nss-drv/stats/cpu_load_ubi

# Kiểm tra phân vùng ổ đĩa F2FS 64GB/128GB:
df -h /mnt/storage

# Kiểm tra bảng chuyển tiếp phần cứng ECM:
cat /sys/kernel/debug/ecm/ecm_db/dump

# Kiểm tra 3 băng tần Wi-Fi:
iwinfo
```

---
*Bản quyền & duy trì bởi [Doanduy09](https://github.com/Doanduy09) - Hỗ trợ kỹ thuật bởi Antigravity Multi-Agent Council.*
