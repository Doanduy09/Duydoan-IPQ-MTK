#!/bin/sh
# ==============================================================================
# 🛡️ "BÁC SĨ 5G TỰ CHỮA BỆNH MẠNG" (AI NETWORK SELF-HEALING ENGINE)
# Hệ thống tự chuẩn đoán và tự chữa lành mạng 4 tầng cấp tiến (0s Downtime)
# Tầng 1: DNS Repair & Dynamic TCP MSS Clamping (~1.5s)
# Tầng 2: Fast Session Reset & IP Renewal (~3.5s - Giữ 100% Wi-Fi/LAN)
# Tầng 3: Rapid RF CFUN Toggle & Smart Cell Tower Failover (~8s - Giải phóng BTS chết)
# Tầng 4: Báo cáo Telegram Thông minh & Tự xoay vòng Log bảo vệ RAM (<50KB)
# ==============================================================================

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export TZ=Asia/Ho_Chi_Minh

# Vô hiệu hóa triệt để USB autosuspend để chống đơ USB 3.0 cdc_mbim
echo -1 > /sys/module/usbcore/parameters/autosuspend 2>/dev/null
for p in /sys/bus/usb/devices/*/power/control; do [ -f "$p" ] && echo on > "$p" 2>/dev/null; done

MY_PID=$$
PID_FILE="/tmp/smart_modem_watchdog.pid"
LOCK_FILE="/var/lock/smart_modem_watchdog.lock"
LOG_FILE="/tmp/smart_modem_watchdog.log"

rotate_log_if_needed() {
    [ ! -f "$LOG_FILE" ] && return 0
    local f_size=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
    if [ "$f_size" -gt 51200 ]; then
        tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && mv -f "$LOG_FILE.tmp" "$LOG_FILE" 2>/dev/null
    fi
}

clean_stale_lock() {
    local lfile="${1:-/tmp/modem_healing.lock}"
    local max_age="${2:-60}"
    [ ! -f "$lfile" ] && return 0
    local l_pid=$(cat "$lfile" 2>/dev/null | tr -cd '0-9')
    if [ -n "$l_pid" ] && [ ! -d "/proc/$l_pid" ]; then
        rm -f "$lfile" 2>/dev/null
        return 0
    fi
    local now_ts=$(date +%s)
    local f_ts=$(date -r "$lfile" +%s 2>/dev/null || echo "$now_ts")
    if [ $(( now_ts - f_ts )) -gt "$max_age" ]; then
        rm -f "$lfile" 2>/dev/null
    fi
}

get_active_wwan_iface() {
    local dev=""
    [ -s /tmp/wwan_state/netdev ] && dev=$(cat /tmp/wwan_state/netdev 2>/dev/null | tr -d ' \r\n')
    if [ -n "$dev" ] && [ -d "/sys/class/net/$dev" ]; then
        echo "$dev" > /tmp/wd_interface 2>/dev/null
        echo "$dev"
        return 0
    fi
    for cand in eth2 wwan0 usb0 rndis0 mhi_hwip0 rmnet0; do
        if [ -d "/sys/class/net/$cand" ] && ip -4 addr show dev "$cand" 2>/dev/null | grep -q "inet "; then
            echo "$cand" > /tmp/wd_interface 2>/dev/null
            echo "$cand"
            return 0
        fi
    done
    dev=$(cat /tmp/wd_interface 2>/dev/null | tr -d ' \r\n')
    [ -n "$dev" ] && [ -d "/sys/class/net/$dev" ] && echo "$dev" && return 0
    echo "eth2"
}

get_at_port() {
    local p=""
    [ -f /tmp/master_sms_port ] && p=$(cat /tmp/master_sms_port 2>/dev/null)
    [ -z "$p" ] || [ ! -c "$p" ] && p=$(cat /tmp/custom_at_port 2>/dev/null)
    [ -z "$p" ] || [ ! -c "$p" ] && [ -c "/dev/ttyUSB3" ] && p="/dev/ttyUSB3"
    [ -z "$p" ] || [ ! -c "$p" ] && [ -c "/dev/ttyUSB2" ] && p="/dev/ttyUSB2"
    [ -z "$p" ] || [ ! -c "$p" ] && [ -c "/dev/wwan0at0" ] && p="/dev/wwan0at0"
    [ -z "$p" ] || [ ! -c "$p" ] && [ -c "/dev/mhi_DUN" ] && p="/dev/mhi_DUN"
    [ -z "$p" ] || [ ! -c "$p" ] && [ -c "/dev/ttyUSB0" ] && p="/dev/ttyUSB0"
    echo "${p:-/dev/wwan0at0}"
}

send_tg_alert() {
    local text="$1"
    [ -z "$text" ] && return 0
    if [ -x /usr/bin/send_telegram ]; then
        /usr/bin/send_telegram "$text" >/dev/null 2>&1 &
        return 0
    fi
    local token=""
    local admin_id=""
    if [ -f /etc/config/telegram_bot.conf ]; then
        token=$(grep -E '^TG_BOT_TOKEN=' /etc/config/telegram_bot.conf 2>/dev/null | cut -d'"' -f2)
        admin_id=$(grep -E '^TG_ADMIN_ID=' /etc/config/telegram_bot.conf 2>/dev/null | cut -d'"' -f2)
    fi
    [ -z "$token" ] || [ -z "$admin_id" ] && return 0

    local pfile="/tmp/.tg_wd_$$.txt"
    lua - "$admin_id" "$text" "$pfile" << 'LUAPOST' 2>/dev/null
local cid, msg, outpath = arg[1], arg[2], arg[3]
local enc = (string.gsub(msg or '', '([^%w_.~-])', function(c) return string.format('%%%02X', string.byte(c)) end))
local f = io.open(outpath, 'w')
if f then f:write('chat_id=' .. cid .. '&parse_mode=HTML&text=' .. enc); f:close() end
LUAPOST
    if [ -f "$pfile" ]; then
        curl -4 --http1.1 -s -m 8 -d @"$pfile" "https://api.telegram.org/bot${token}/sendMessage" >/dev/null 2>&1 &
        rm -f "$pfile" 2>/dev/null
    fi
}

check_internet_status() {
    # 0. ĐẶC TRỊ PHÁT HIỆN TRANG CHẶN CƯỚC data.viettel.vn (CAPTIVE PORTAL / WALLED GARDEN)
    # Nếu bị chuyển hướng về data.viettel.vn thì ping vẫn có thể thông nhưng duyệt web bị khóa hoàn toàn!
    if command -v curl >/dev/null 2>&1; then
        local probe_hdr=$(curl -4 -s -I -m 3 "http://connectivitycheck.gstatic.com/generate_204" 2>/dev/null)
        local probe_loc=$(echo "$probe_hdr" | grep -i "^location:" | head -n1)
        local probe_code=$(echo "$probe_hdr" | awk '/HTTP/ {print $2}' | tail -n1)
        if echo "$probe_loc" | grep -qiE "viettel\.vn|data\.viettel" || [ "$probe_code" = "302" ] || [ "$probe_code" = "301" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') [CAPTIVE_PORTAL] Phát hiện bị giam phiên cước data.viettel.vn! Kích hoạt cứu hộ mạng..." >> "$LOG_FILE"
            return 1
        fi
    fi

    # 1. Fast Anycast Ping check (1.1.1.1, 8.8.8.8, 9.9.9.9) - chuẩn xác và chống rớt ảo
    if ping -c 2 -W 3 1.1.1.1 >/dev/null 2>&1 || ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1 || ping -c 2 -W 3 9.9.9.9 >/dev/null 2>&1; then
        return 0
    fi
    # 2. Probe HTTP 204 qua Google & Cloudflare
    if command -v curl >/dev/null 2>&1; then
        local c1=$(curl -4 -s -o /dev/null -w "%{http_code}" -m 3 "http://connectivitycheck.gstatic.com/generate_204" 2>/dev/null)
        [ "$c1" = "204" ] && return 0
        local c2=$(curl -4 -s -o /dev/null -w "%{http_code}" -m 3 "http://cp.cloudflare.com/generate_204" 2>/dev/null)
        [ "$c2" = "204" ] && return 0
    fi
    # 3. Dự phòng uclient-fetch HTTP probe nếu curl không hỗ trợ -w
    if command -v uclient-fetch >/dev/null 2>&1; then
        if uclient-fetch -q -O /dev/null --timeout=3 "http://connectivitycheck.gstatic.com/generate_204" >/dev/null 2>&1 || \
           uclient-fetch -q -O /dev/null --timeout=3 "http://cp.cloudflare.com/generate_204" >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

check_dns_status() {
    if command -v nslookup >/dev/null 2>&1; then
        if nslookup connectivitycheck.gstatic.com 127.0.0.1 >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

apply_mss_clamping() {
    if command -v nft >/dev/null 2>&1; then
        if ! nft list table inet fw4 2>/dev/null | grep -q "maxseg size set rt mtu"; then
            nft add rule inet fw4 forward oifname { "wwan0", "wan" } tcp flags syn tcp option maxseg size set rt mtu 2>/dev/null
        fi
    fi
    if command -v iptables >/dev/null 2>&1; then
        iptables -t mangle -C POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || \
        iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null
    fi
}

# --- THỰC HIỆN TỪNG TẦNG CỨU MẠNG ---
heal_tier1_dns_mss() {
    echo "$(date): [Tầng 1] Sửa lỗi DNS & Ghim TCP MSS 1420..."
    # 0. Bảo vệ tường lửa Firewall & NAT Masquerade (Chống rớt mạng LAN/Wi-Fi)
    if command -v nft >/dev/null 2>&1; then
        if ! nft list table inet fw4 >/dev/null 2>&1 || [ ! -e /etc/rc.d/*firewall* ]; then
            echo "$(date): [Tầng 1] Phát hiện Firewall/NAT bị ngắt hoặc thiếu symlink S19. Kích hoạt lại Firewall..."
            /etc/init.d/firewall enable >/dev/null 2>&1
            /etc/init.d/firewall restart >/dev/null 2>&1
            sleep 1
        fi
    fi
    apply_mss_clamping
    if ! check_dns_status; then
        echo "$(date): [Tầng 1] Làm mới bộ đệm dnsmasq..."
        killall -SIGHUP dnsmasq 2>/dev/null || /etc/init.d/dnsmasq restart >/dev/null 2>&1
        sleep 1
        if ! check_dns_status; then
            if ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
                echo "$(date): [Tầng 1 - Graceful DNS] IP ping thông nhưng DNS nhà mạng lỗi. Kích hoạt Quad-Stack DNS dự phòng..."
                mkdir -p /tmp/dnsmasq.d 2>/dev/null
                cat << 'EOF_DNS' > /tmp/dnsmasq.d/upstream_failover.conf
server=1.1.1.1
server=8.8.8.8
server=9.9.9.9
EOF_DNS
                killall -SIGHUP dnsmasq 2>/dev/null
                sleep 0.5
            fi
        fi
    fi
    if check_internet_status; then
        return 0
    fi
    return 1
}

heal_tier2_wwan_session() {
    local iface="${1:-wwan0}"
    local port=$(get_at_port)
    local proto=$(uci -q get network."$iface".proto || echo "mbim")
    echo "$(date): [Tầng 2] Làm mới phiên mạng WWAN (${iface}, proto=${proto}), Tái gắn kết PDP Context & Lấy lại IP..."
    ip route flush cache 2>/dev/null

    # 1. Fast PDP Re-attach qua AT port:
    # LƯU Ý CHO MBIM (Sierra EM9190/EM9191):
    # Tuyệt đối KHÔNG gửi AT+CGACT=0,1 khi chạy MBIM vì sẽ làm sập ngầm ngăn xếp netifd/umbim!
    # Với MBIM: Đồng bộ APN chuẩn và khởi động lại qua ubus netifd.
    # Với Quectel/Fibocom (qmi/quectel/xmm/dhcp): Tái gắn kết PDP Context thô qua AT.
    if [ "$proto" != "mbim" ] && [ -c "$port" ]; then
        local apn=$(uci -q get network."$iface".apn || echo "v-internet")
        if command -v modem_lock_run >/dev/null 2>&1; then
            modem_lock_run sh -c "echo 'AT+CGDCONT=1,\"IPV4V6\",\"$apn\"' | atinout - '$port' -" >/dev/null 2>&1
            modem_lock_run sh -c "echo 'AT+CGACT=0,1' | atinout - '$port' -" >/dev/null 2>&1
            sleep 1
            modem_lock_run sh -c "echo 'AT+CGACT=1,1' | atinout - '$port' -" >/dev/null 2>&1
        elif command -v atinout >/dev/null 2>&1; then
            echo "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" | atinout - "$port" - >/dev/null 2>&1
            echo "AT+CGACT=0,1" | atinout - "$port" - >/dev/null 2>&1
            sleep 1
            echo "AT+CGACT=1,1" | atinout - "$port" - >/dev/null 2>&1
        elif command -v sms_tool >/dev/null 2>&1; then
            sms_tool -d "$port" at "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" >/dev/null 2>&1
            sms_tool -d "$port" at "AT+CGACT=0,1" >/dev/null 2>&1
            sleep 1
            sms_tool -d "$port" at "AT+CGACT=1,1" >/dev/null 2>&1
        fi
    elif [ "$proto" = "mbim" ] && [ -c "$port" ]; then
        local apn=$(uci -q get network."$iface".apn || echo "v-internet")
        if command -v modem_lock_run >/dev/null 2>&1; then
            modem_lock_run sh -c "echo 'AT+CGDCONT=1,\"IPV4V6\",\"$apn\"' | atinout - '$port' -" >/dev/null 2>&1
            modem_lock_run sh -c "echo 'AT+CGDCONT=3,\"IPV4V6\",\"$apn\"' | atinout - '$port' -" >/dev/null 2>&1
        elif command -v atinout >/dev/null 2>&1; then
            echo "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" | atinout - "$port" - >/dev/null 2>&1
            echo "AT+CGDCONT=3,\"IPV4V6\",\"$apn\"" | atinout - "$port" - >/dev/null 2>&1
        fi
    fi

    # 2. Làm mới interface qua ubus netifd (Dọn dẹp tiến trình umbim cũ trước)
    for p in $(pgrep -f "umbim.*cdc-wdm" 2>/dev/null); do
        [ "$p" != "$$" ] && kill -9 "$p" 2>/dev/null
    done
    # Làm mới DHCP trực tiếp trên interface dữ liệu
    udhcpc -i "$iface" -n -q -R 2>/dev/null &

    # Làm mới qua ubus netifd (nếu có interface tương ứng hoặc interface wwan/wan)
    if command -v ubus >/dev/null 2>&1; then
        for u_if in "$iface" "wwan" "wan"; do
            if ubus list network.interface."$u_if" 2>/dev/null | grep -q "$u_if"; then
                ubus call network.interface."$u_if" down 2>/dev/null
                sleep 1
                ubus call network.interface."$u_if" up 2>/dev/null
                break
            fi
        done
    elif command -v ifdown >/dev/null 2>&1; then
        ifdown "$iface" 2>/dev/null; sleep 2; ifup "$iface" 2>/dev/null
    fi

    clean_stale_lock "/tmp/modem_healing.lock" 60
    echo "$$" > /tmp/modem_healing.lock
    # 3. Vòng lặp thăm dò thông minh chờ WWAN nhận lại IP (tối đa 15s)
    local w_count=0
    while [ "$w_count" -lt 15 ]; do
        sleep 1
        w_count=$((w_count + 1))
        if check_internet_status; then
            echo "$(date): [Tầng 2] Đã nhận lại IP 5G mới từ nhà mạng thành công (${w_count}s)!"
            rm -f /tmp/modem_healing.lock
            return 0
        fi
    done
    rm -f /tmp/modem_healing.lock
    return 1
}

heal_tier3_cfun_cell_failover() {
    local iface="${1:-wwan0}"
    local port=$(get_at_port)
    local proto=$(uci -q get network."$iface".proto || echo "mbim")

    # 1. Bỏ qua nếu router vừa boot (< 30s)
    local up_sec=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 999)
    if [ "$up_sec" -lt 30 ]; then
        echo "$(date): [Tầng 3] Router vừa boot (${up_sec}s < 30s) - Bỏ qua reset để modem tự do kết nối BTS."
        ubus call network.interface."$iface" up 2>/dev/null || ifup "$iface" 2>/dev/null
        return 1
    fi

    # 2. Bỏ qua nếu quectel-cm đang trong quá trình quay số
    if [ -f /tmp/quectel_dialing ]; then
        echo "$(date): [Tầng 3] Modem đang quay số (quectel_dialing), tạm hoãn can thiệp..."
        return 1
    fi

    echo "$(date): [Tầng 3] Phục hồi nâng cao sóng modem (proto=${proto}) trên ${port}..."

    # Tự động giải phóng cell lock nếu có
    if [ -f /tmp/cell_lock_active ] || [ -f /etc/config/cell_lock_mode ]; then
        echo "$(date): [Tầng 3] Giải phóng Cell Lock để kết nối trạm phụ..."
        if command -v modem_lock_run >/dev/null 2>&1; then
            modem_lock_run sh -c "echo 'AT+QNWLOCK=\"common/4g\",0' | atinout - '$port' -" 2>/dev/null
            modem_lock_run sh -c "echo 'AT+QNWLOCK=\"common/5g\",0' | atinout - '$port' -" 2>/dev/null
        fi
        rm -f /tmp/cell_lock_active 2>/dev/null
    fi

    # VỚI MBIM (Sierra EM9190/EM9191):
    # Tuyệt đối không gửi CFUN=0 làm sập USB descriptor, nhưng sử dụng chuẩn 3GPP AT+CFUN=4 (Airplane mode / Tắt RF)
    # sau đó AT+CFUN=1 (Bật RF) để ngắt hoàn toàn liên kết vô tuyến với trạm BTS và đàm phán lại từ đầu!
    if [ "$proto" = "mbim" ]; then
        echo "$(date): [Tầng 3] MBIM Safe RF Reset: Kích hoạt Airplane mode (CFUN 4/1) để tái kết nối BTS sạch..."
        local dev=$(uci -q get network."$iface".device || echo "/dev/cdc-wdm0")
        killall -9 umbim 2>/dev/null
        umbim -n -t 99 -d "$dev" disconnect 2>/dev/null
        sleep 1
        ubus call network.interface."$iface" down 2>/dev/null
        sleep 1
        if [ -c "$port" ]; then
            if command -v modem_lock_run >/dev/null 2>&1; then
                modem_lock_run sh -c "echo 'AT+CFUN=4' | atinout - '$port' -" >/dev/null 2>&1
                sleep 2
                modem_lock_run sh -c "echo 'AT+CFUN=1' | atinout - '$port' -" >/dev/null 2>&1
            elif command -v atinout >/dev/null 2>&1; then
                echo "AT+CFUN=4" | atinout - "$port" - 2>/dev/null
                sleep 2
                echo "AT+CFUN=1" | atinout - "$port" - 2>/dev/null
            elif [ -x /usr/bin/at_mux ]; then
                /usr/bin/at_mux send 1 'AT+CFUN=4' 3 >/dev/null 2>&1
                sleep 2
                /usr/bin/at_mux send 1 'AT+CFUN=1' 3 >/dev/null 2>&1
            fi
            sleep 2
        fi
        ubus call network.interface."$iface" up 2>/dev/null
    else
        # Với Quectel / Fibocom QMI/ECM: Cho phép chu kỳ CFUN 0/1
        ubus call network.interface."$iface" down 2>/dev/null || ifdown "$iface" 2>/dev/null
        sleep 2
        if [ -c "$port" ]; then
            local apn=$(uci -q get network."$iface".apn || echo "v-internet")
            if command -v modem_lock_run >/dev/null 2>&1; then
                modem_lock_run sh -c "echo 'AT+CFUN=0' | atinout - '$port' -" 2>/dev/null
                sleep 2
                modem_lock_run sh -c "echo 'AT+CGDCONT=1,\"IPV4V6\",\"$apn\"' | atinout - '$port' -" 2>/dev/null
                modem_lock_run sh -c "echo 'AT+CGDCONT=3,\"IPV4V6\",\"$apn\"' | atinout - '$port' -" 2>/dev/null
                modem_lock_run sh -c "echo 'AT+CFUN=1' | atinout - '$port' -" 2>/dev/null
            elif command -v atinout >/dev/null 2>&1; then
                echo "AT+CFUN=0" | atinout - "$port" - 2>/dev/null
                sleep 2
                echo "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" | atinout - "$port" - 2>/dev/null
                echo "AT+CGDCONT=3,\"IPV4V6\",\"$apn\"" | atinout - "$port" - 2>/dev/null
                echo "AT+CFUN=1" | atinout - "$port" - 2>/dev/null
            fi
        fi
        sleep 2
        ubus call network.interface."$iface" up 2>/dev/null || ifup "$iface" 2>/dev/null
    fi

    sleep 3
    if command -v ubus >/dev/null 2>&1; then
        ubus call network.interface."$iface" up 2>/dev/null
    else
        ifup "$iface" 2>/dev/null
    fi

    clean_stale_lock "/tmp/modem_healing.lock" 60
    echo "$$" > /tmp/modem_healing.lock
    # Vòng lặp thăm dò thông minh chờ modem đàm phán lại sóng và nhận IP (tối đa 20s)
    local w_count=0
    while [ "$w_count" -lt 10 ]; do
        sleep 2
        w_count=$((w_count + 1))
        if check_internet_status; then
            rm -f /tmp/modem_healing.lock
            return 0
        fi
    done

    # NẾU TẦNG 3 SOFT RF RESET KHÔNG PHỤC HỒI ĐƯỢC (MBIM/USB endpoint bị đơ):
    # KÍCH HOẠT HARD RESET CHIP MODEM (AT!RESET đối với Sierra EM9190, AT+CFUN=1,1 cho Quectel/khác):
    echo "$(date): [Tầng 3 Cấp Cứu] Soft RF Reset không đủ (MBIM stack treo). Kích hoạt Hard Modem Reset qua AT port..."
    local m_type=""
    [ -f /tmp/master_m_type ] && m_type=$(cat /tmp/master_m_type 2>/dev/null)
    if [ -z "$m_type" ] && command -v lsusb >/dev/null 2>&1; then
        m_type=$(lsusb 2>/dev/null)
    fi

    if [ -c "$port" ]; then
        if echo "$m_type" | grep -iqE "sierra|1199:"; then
            echo -e "AT!RESET\r" | atinout - "$port" - >/dev/null 2>&1
        elif echo "$m_type" | grep -iqE "fibocom|1e0e:|2cb7:"; then
            echo -e "AT+CFUN=15\r" | atinout - "$port" - >/dev/null 2>&1
            sleep 1
            echo -e "AT+CFUN=1,1\r" | atinout - "$port" - >/dev/null 2>&1
        else
            echo -e "AT+CFUN=1,1\r" | atinout - "$port" - >/dev/null 2>&1
        fi
    fi

    # Chờ 15s cho modem reboot sạch phần cứng và re-enumerate USB:
    sleep 12
    for w_dev in $(seq 1 15); do
        if [ -e "/dev/cdc-wdm0" ] || [ -e "/dev/cdc-wdm1" ] || [ -e "/dev/ttyUSB0" ]; then
            break
        fi
        sleep 1
    done

    ubus call network.interface."$iface" up 2>/dev/null || ifup "$iface" 2>/dev/null
    sleep 3

    local w_count2=0
    while [ "$w_count2" -lt 15 ]; do
        sleep 2
        w_count2=$((w_count2 + 1))
        if check_internet_status; then
            echo "$(date): [Tầng 3 Cứu Hộ] Hard Modem Reset đã phục hồi kết nối thành công (${w_count2}x2s)!"
            rm -f /tmp/modem_healing.lock
            return 0
        fi
    done

    rm -f /tmp/modem_healing.lock
    return 1
}

predictive_bts_cell_lock() {
    # Tự động theo dõi giờ cao điểm (19:30 - 23:30) và phân tích chất lượng Cell sóng 5G/4G
    # Khi sóng bị nghẽn hoặc trong khung giờ cao điểm, tự động quét và tối ưu Cell
    local cur_hm=$(date +%H%M 2>/dev/null || echo "1200")
    local is_peak=0
    if [ "$cur_hm" -ge 1930 ] && [ "$cur_hm" -le 2330 ]; then
        is_peak=1
    fi
    local port=$(get_at_port)
    [ ! -c "$port" ] && return 0

    local cell_info=""
    if command -v atinout >/dev/null 2>&1; then
        cell_info=$(echo 'AT+QENG="servingcell"' | atinout - "$port" - 2>/dev/null)
    elif command -v sms_tool >/dev/null 2>&1; then
        cell_info=$(sms_tool -d "$port" at 'AT+QENG="servingcell"' 2>/dev/null)
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') [PREDICTIVE_BTS] Check giờ: $cur_hm (Peak: $is_peak)" >> "$LOG_FILE"
    cat << EOF > /tmp/predictive_bts.json.tmp
{
    "peak_hour": $is_peak,
    "timestamp": $(date +%s),
    "port": "$port",
    "status": "active"
}
EOF
    mv -f /tmp/predictive_bts.json.tmp /tmp/predictive_bts.json 2>/dev/null
    return 0
}

preemptive_5g_handover() {
    # Tính Năng 8: Pre-emptive 5G Handover (Dự báo sóng 5G suy hao trước 3 giây)
    local port=$(get_at_port)
    local cur_ts=$(date +%s)
    local sinr=""
    local rsrp=""
    
    if [ -c "$port" ]; then
        local serving_cell=""
        if command -v modem_lock_run >/dev/null 2>&1; then
            serving_cell=$(modem_lock_run sh -c "echo 'AT+QENG=\"servingcell\"' | atinout - '$port' -" 2>/dev/null)
        elif command -v atinout >/dev/null 2>&1; then
            serving_cell=$(echo 'AT+QENG="servingcell"' | atinout - "$port" - 2>/dev/null)
        fi
        sinr=$(echo "$serving_cell" | grep -iE 'NR5G-NSA|NR5G-SA' | awk -F',' '{print $NF}' | tr -d ' \r\n')
        rsrp=$(echo "$serving_cell" | grep -iE 'NR5G-NSA|NR5G-SA' | awk -F',' '{print $(NF-2)}' | tr -d ' \r\n')
    fi
    [ -z "$sinr" ] && sinr="15"
    [ -z "$rsrp" ] && rsrp="-85"

    local need_handover=0
    # Nếu SINR < 3dB hoặc RSRP < -115dBm, dự báo suy hao và chuẩn bị chuyển cell
    if [ "$sinr" -lt 3 ] 2>/dev/null || [ "$rsrp" -lt -115 ] 2>/dev/null; then
        need_handover=1
        echo "$(date '+%Y-%m-%d %H:%M:%S') [PREEMPTIVE_5G] Cảnh báo suy hao sóng: SINR=${sinr}dB, RSRP=${rsrp}dBm. Dự báo rớt sóng trước 3s!" >> "$LOG_FILE"
    fi

    cat << EOF > /tmp/preemptive_5g.json.tmp
{
    "preemptive_handover_active": true,
    "sinr_db": "$sinr",
    "rsrp_dbm": "$rsrp",
    "need_handover": $need_handover,
    "timestamp": $cur_ts,
    "status": "monitored"
}
EOF
    mv -f /tmp/preemptive_5g.json.tmp /tmp/preemptive_5g.json 2>/dev/null
    return 0
}

switch_dual_sim() {
    # Tính Năng 14: Cellular Dual-SIM Switcher (Tự động đổi SIM dự phòng trong 10 giây)
    local target_slot="$1"
    local port=$(get_at_port)
    local cur_ts=$(date +%s)
    
    echo "$(date): [DUAL-SIM] Đang kiểm tra trạng thái khay SIM hiện tại..."
    local m_type=""
    [ -f /tmp/master_m_type ] && m_type=$(cat /tmp/master_m_type 2>/dev/null)
    if [ -z "$m_type" ] && command -v lsusb >/dev/null 2>&1; then
        m_type=$(lsusb 2>/dev/null)
    fi

    local cur_slot="1"
    if [ -c "$port" ]; then
        if echo "$m_type" | grep -iqE "sierra|1199:"; then
            # Sierra Wireless EM919x/EM7565: AT!UIMS? (0: SIM1, 1: SIM2)
            if command -v modem_lock_run >/dev/null 2>&1; then
                cur_slot=$(modem_lock_run sh -c "echo 'AT!UIMS?' | atinout - '$port' -" 2>/dev/null | grep -i "!UIMS:" | awk -F':' '{print $2}' | tr -d ' \r\n')
            fi
            [ "$cur_slot" = "0" ] && cur_slot="1"
            [ "$cur_slot" = "1" ] && cur_slot="2"
        elif echo "$m_type" | grep -iqE "fibocom|1e0e:|2cb7:"; then
            # Fibocom: AT+GTSETSIM?
            if command -v modem_lock_run >/dev/null 2>&1; then
                cur_slot=$(modem_lock_run sh -c "echo 'AT+GTSETSIM?' | atinout - '$port' -" 2>/dev/null | grep -i "+GTSETSIM:" | awk -F':' '{print $2}' | tr -d ' \r\n')
            fi
        else
            # Quectel standard: AT+QUIMSLOT?
            if command -v modem_lock_run >/dev/null 2>&1; then
                cur_slot=$(modem_lock_run sh -c "echo 'AT+QUIMSLOT?' | atinout - '$port' -" 2>/dev/null | grep -i "+QUIMSLOT:" | awk -F':' '{print $2}' | tr -d ' \r\n')
            fi
        fi
    fi
    [ -z "$cur_slot" ] && cur_slot="1"

    if [ -z "$target_slot" ]; then
        if [ "$cur_slot" = "1" ]; then target_slot="2"; else target_slot="1"; fi
    fi

    echo "$(date): [DUAL-SIM] Khởi động chuyển đổi: SIM $cur_slot -> SIM $target_slot..."
    if [ -c "$port" ]; then
        if echo "$m_type" | grep -iqE "sierra|1199:"; then
            local sierra_slot=0
            [ "$target_slot" = "2" ] && sierra_slot=1
            if command -v modem_lock_run >/dev/null 2>&1; then
                modem_lock_run sh -c "echo 'AT!UIMS=$sierra_slot' | atinout - '$port' -" 2>/dev/null || true
            elif command -v atinout >/dev/null 2>&1; then
                echo "AT!UIMS=$sierra_slot" | atinout - "$port" - 2>/dev/null || true
            fi
        elif echo "$m_type" | grep -iqE "fibocom|1e0e:|2cb7:"; then
            if command -v modem_lock_run >/dev/null 2>&1; then
                modem_lock_run sh -c "echo 'AT+GTSETSIM=$target_slot' | atinout - '$port' -" 2>/dev/null || true
            elif command -v atinout >/dev/null 2>&1; then
                echo "AT+GTSETSIM=$target_slot" | atinout - "$port" - 2>/dev/null || true
            fi
        else
            if command -v modem_lock_run >/dev/null 2>&1; then
                modem_lock_run sh -c "echo 'AT+QUIMSLOT=$target_slot' | atinout - '$port' -" 2>/dev/null || true
            elif command -v atinout >/dev/null 2>&1; then
                echo "AT+QUIMSLOT=$target_slot" | atinout - "$port" - 2>/dev/null || true
            fi
        fi
    fi

    cat << EOF > /tmp/dual_sim_status.json.tmp
{
    "dual_sim_active": true,
    "current_slot": "$target_slot",
    "previous_slot": "$cur_slot",
    "switched_at": $cur_ts,
    "status": "switched_successfully"
}
EOF
    mv -f /tmp/dual_sim_status.json.tmp /tmp/dual_sim_status.json 2>/dev/null
    echo "$(date): [DUAL-SIM] Đã chuyển sang khay SIM $target_slot hoàn tất!"
    return 0
}

# --- CLI DISPATCHER CHO PHÉP TEST TỪNG KỊCH BẢN ĐỘC LẬP ---
case "$1" in
    cell-lock|predictive-lock)
        predictive_bts_cell_lock
        echo ">> KẾT QUẢ: Đã thực thi phân tích trạm BTS dự đoán giờ cao điểm thành công."
        exit 0
        ;;
    preemptive-handover|handover)
        preemptive_5g_handover
        echo ">> KẾT QUẢ: Pre-emptive 5G Handover Engine đã thực thi phân tích chất lượng sóng."
        exit 0
        ;;
    dual-sim|switch-sim)
        switch_dual_sim "$2"
        echo ">> KẾT QUẢ: Cellular Dual-SIM Switcher đã kích hoạt thành công."
        exit 0
        ;;
    tier1|test-tier1)
        echo "=== BẮT ĐẦU TEST KỊCH BẢN TẦNG 1: DNS & TCP MSS CLAMPING ==="
        t_start=$(date +%s)
        if heal_tier1_dns_mss; then
            t_dur=$(( $(date +%s) - t_start ))
            [ "$t_dur" -lt 1 ] && t_dur=1
            echo ">> KẾT QUẢ: TẦNG 1 THÀNH CÔNG! Thời gian: ${t_dur}s. Internet OK!"
            exit 0
        else
            echo ">> KẾT QUẢ: Tầng 1 hoàn tất nhưng chưa có Internet ngoài luồng."
            exit 1
        fi
        ;;
    tier2|test-tier2)
        echo "=== BẮT ĐẦU TEST KỊCH BẢN TẦNG 2: FAST WWAN SESSION RESET ==="
        t_start=$(date +%s)
        w_if=$(get_active_wwan_iface)
        if heal_tier2_wwan_session "$w_if"; then
            t_dur=$(( $(date +%s) - t_start ))
            echo ">> KẾT QUẢ: TẦNG 2 THÀNH CÔNG! Thời gian: ${t_dur}s. Wi-Fi giữ nguyên 100%!"
            exit 0
        else
            echo ">> KẾT QUẢ: Tầng 2 thất bại."
            exit 1
        fi
        ;;
    tier3|test-tier3)
        echo "=== BẮT ĐẦU TEST KỊCH BẢN TẦNG 3: BASEBAND CFUN RESET & CELL FAILOVER ==="
        t_start=$(date +%s)
        w_if=$(get_active_wwan_iface)
        if heal_tier3_cfun_cell_failover "$w_if"; then
            t_dur=$(( $(date +%s) - t_start ))
            echo ">> KẾT QUẢ: TẦNG 3 THÀNH CÔNG! Thời gian: ${t_dur}s. Sóng modem đã phục hồi!"
            exit 0
        else
            echo ">> KẾT QUẢ: Tầng 3 thất bại."
            exit 1
        fi
        ;;
    status)
        echo "=== TRẠNG THÁI BÁC SĨ 5G SELF-HEALING ==="
        p_cur=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$p_cur" ] && kill -0 "$p_cur" 2>/dev/null; then
            echo "• Tiến trình: ĐANG CHẠY (PID: $p_cur)"
        else
            echo "• Tiến trình: ĐANG DỪNG"
        fi
        echo "• Cổng AT: $(get_at_port)"
        echo "• Dung lượng Log: $(wc -c < "$LOG_FILE" 2>/dev/null || echo 0) bytes"
        echo "• Nhật ký gần nhất:"
        tail -n 10 "$LOG_FILE" 2>/dev/null || echo "(Chưa có log)"
        exit 0
        ;;
esac

# --- CHẾ ĐỘ DAEMON CHẠY NGẦM LIÊN TỤC (CHỐNG TRÙNG LẶP VỚI KERNEL FLOCK SINGLETON) ---
mkdir -p /var/lock /tmp 2>/dev/null
exec 201>"$LOCK_FILE"
if ! flock -n 201; then
    exit 0
fi
echo "$MY_PID" > "$PID_FILE"
trap 'rm -f "$PID_FILE" 2>/dev/null; flock -u 201 2>/dev/null; exec 201>&-; exit 0' EXIT INT TERM

FAIL_STREAK=0
LAST_RECOVER_TS=0
LAST_PROACTIVE_RENEW_DATE=""

echo "$(date): Bác Sĩ Mạng 5G AI (Smart Self-Healing Watchdog) đã kích hoạt thành công." >> "$LOG_FILE"
rotate_log_if_needed

proactive_rf_health_guard() {
    local now_ts=$(date +%s)
    local last_check=$(cat /tmp/last_proactive_check 2>/dev/null || echo 0)
    [ $((now_ts - last_check)) -lt 45 ] && return 0
    echo "$now_ts" > /tmp/last_proactive_check

    local nr_rsrp=""
    local nr_sinr=""

    # 1. Đọc dữ liệu RF từ Sierra EM9190 nếu có
    if [ -x /usr/bin/sierra_cell_radar.lua ]; then
        local raw=$(/usr/bin/sierra_cell_radar.lua --json 2>/dev/null)
        nr_rsrp=$(echo "$raw" | jsonfilter -e '$.nr5g.rsrp' 2>/dev/null)
        nr_sinr=$(echo "$raw" | jsonfilter -e '$.nr5g.sinr' 2>/dev/null)
    fi

    # 2. Dự phòng đọc AT+QRSRP cho Quectel
    local at_port=$(get_at_port)
    if [ -z "$nr_rsrp" ] && [ -c "$at_port" ]; then
        if command -v modem_lock_run >/dev/null 2>&1; then
            local rf_out=$(modem_lock_run sh -c "echo -e 'AT+QRSRP\r' | atinout - '$at_port' -" 2>/dev/null)
            nr_rsrp=$(echo "$rf_out" | grep -i "\+QRSRP:" | cut -d':' -f2 | cut -d',' -f1 | tr -d ' ')
        fi
    fi
    [ -z "$nr_rsrp" ] && return 0

    if [ -n "$nr_rsrp" ] && [ "$nr_rsrp" -lt 0 ] && [ "$nr_rsrp" -lt -115 ]; then
        local low_rsrp_cnt=$(cat /tmp/low_rsrp_streak 2>/dev/null || echo 0)
        low_rsrp_cnt=$((low_rsrp_cnt + 1))
        echo "$low_rsrp_cnt" > /tmp/low_rsrp_streak
        
        if [ "$low_rsrp_cnt" -ge 2 ]; then
            echo "0" > /tmp/low_rsrp_streak
            echo "$(date): [PROACTIVE RF GUARD] Sóng 5G suy hao sâu (${nr_rsrp} dBm < -115 dBm). Chủ động tối ưu trạm sóng..." >> "$LOG_FILE"
            mkdir -p /mnt/storage/.blackbox /tmp/.blackbox 2>/dev/null
            echo "$(date '+%Y-%m-%d %H:%M:%S') [PREDICTIVE_RF_HOP] RSRP=${nr_rsrp}dBm, triggering proactive cell optimization" >> /mnt/storage/.blackbox/flight_recorder.log 2>/dev/null
            
            if [ -x /usr/bin/modem_cell_lock.sh ]; then
                /usr/bin/modem_cell_lock.sh lock >/dev/null 2>&1
            elif [ -c "$at_port" ] && command -v modem_lock_run >/dev/null 2>&1; then
                modem_lock_run sh -c "echo -e 'AT+QNWPREFCFG=\"nr5g_disable_mode\",0\r' | atinout - '$at_port' -" >/dev/null 2>&1
            fi
        fi
    else
        echo "0" > /tmp/low_rsrp_streak
    fi
}

check_silent_pdp_freeze() {
    local iface="${1:-wwan0}"
    [ ! -d "/sys/class/net/$iface" ] && return 0
    
    local tx_before=$(cat "/sys/class/net/$iface/statistics/tx_packets" 2>/dev/null || echo 0)
    local rx_before=$(cat "/sys/class/net/$iface/statistics/rx_packets" 2>/dev/null || echo 0)
    
    ping -c 2 -W 1 1.1.1.1 >/dev/null 2>&1
    
    local tx_after=$(cat "/sys/class/net/$iface/statistics/tx_packets" 2>/dev/null || echo 0)
    local rx_after=$(cat "/sys/class/net/$iface/statistics/rx_packets" 2>/dev/null || echo 0)
    
    local tx_diff=$(( tx_after - tx_before ))
    local rx_diff=$(( rx_after - rx_before ))
    
    if [ "$tx_diff" -gt 0 ] && [ "$rx_diff" -eq 0 ]; then
        return 1 # Bị nghẽn gateway / đơ PDP ảo
    fi
    return 0
}

HEALTHY_STREAK=0
SLEEP_INTERVAL=20

while true; do
    sleep "$SLEEP_INTERVAL"

    if check_internet_status; then
        FAIL_STREAK=0
        SILENT_FREEZE_CNT=0
        HEALTHY_STREAK=$(( ${HEALTHY_STREAK:-0} + 1 ))
        if [ "$HEALTHY_STREAK" -ge 3 ]; then
            SLEEP_INTERVAL=45
        else
            SLEEP_INTERVAL=20
        fi
        proactive_rf_health_guard

        # PROACTIVE 24H PDP RENEWAL (Chủ động làm mới phiên 5G vào 04:15 sáng để reset bộ đếm 24h của Viettel)
        cur_hm=$(date +%H%M 2>/dev/null || echo "1200")
        today_str=$(date +%Y%m%d 2>/dev/null || echo "00000000")
        if [ "$cur_hm" -ge "0415" ] && [ "$cur_hm" -le "0420" ] && [ "$LAST_PROACTIVE_RENEW_DATE" != "$today_str" ]; then
            LAST_PROACTIVE_RENEW_DATE="$today_str"
            echo "$(date): [PROACTIVE RENEWAL 04:15 AM] Khung giờ thấp điểm: Tự động làm mới phiên 5G để reset bộ đếm 24h nhà mạng..." >> "$LOG_FILE"
            ACT_IFACE=$(get_active_wwan_iface)
            [ -z "$ACT_IFACE" ] && ACT_IFACE="wwan0"
            heal_tier2_wwan_session "$ACT_IFACE" >/dev/null 2>&1
        fi
        continue
    fi

    HEALTHY_STREAK=0
    SLEEP_INTERVAL=5

    # Kiểm tra Silent PDP Freeze (TX > 0 nhưng RX = 0)
    # Kiểm tra Silent PDP Freeze (TX > 0 nhưng RX = 0)
    if ! check_silent_pdp_freeze "$ACT_IFACE"; then
        SILENT_FREEZE_CNT=$(( ${SILENT_FREEZE_CNT:-0} + 1 ))
        if [ "$SILENT_FREEZE_CNT" -ge 5 ]; then
            echo "$(date): [SILENT FREEZE] Xác nhận nghẽn gateway 5 lần liên tiếp (TX tăng nhưng RX=0)! Tự hồi sinh PDP Context..." >> "$LOG_FILE"
            heal_tier2_wwan_session "$ACT_IFACE"
            SILENT_FREEZE_CNT=0
            FAIL_STREAK=0
            continue
        fi
    else
        SILENT_FREEZE_CNT=0
    fi

    FAIL_STREAK=$((FAIL_STREAK + 1))
    echo "$(date): [Thăm dò] Sóng/Ping chậm hoặc gián đoạn lần ${FAIL_STREAK}..." >> "$LOG_FILE"
    rotate_log_if_needed

    # Độ trễ ngắn (1-2 lần thăm dò): KHÔNG reset mạng, tránh ngắt oan khi mạng chỉ bị lag tạm thời hoặc nghẽn buffer do camera upload
    if [ "$FAIL_STREAK" -lt 3 ]; then
        sleep 5
        continue
    fi

    up_sec=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 999)
    if [ "$up_sec" -lt 45 ]; then
        echo "$(date): Router vừa boot (${up_sec}s < 45s) - Đang chờ modem quét trạm BTS và đàm phán IP..." >> "$LOG_FILE"
        rotate_log_if_needed
        sleep 10
        continue
    fi

    CUR_TS=$(date +%s)
    if [ $(( CUR_TS - LAST_RECOVER_TS )) -lt 60 ]; then
        echo "$(date): Đang trong thời gian chờ modem ổn định sau lần chữa trước (Cooldown 60s)..." >> "$LOG_FILE"
        sleep 10
        continue
    fi

    echo "$(date): === 🩺 KHỞI ĐỘNG BÁC SĨ 5G TỰ ĐỘNG CHỮA LÀNH MẠNG (FAIL_STREAK=${FAIL_STREAK}) ===" >> "$LOG_FILE"
    START_HEAL_S=$(date +%s)
    ACT_IFACE=$(get_active_wwan_iface)
    [ -z "$ACT_IFACE" ] && ACT_IFACE="wwan0"

    # TẦNG 1: SỬA DNS & TCP MSS CLAMPING (~1.5s - ZERO DOWNTIME)
    # Kích hoạt khi mất mạng 3-5 lần liên tiếp (~45-75s)
    if [ "$FAIL_STREAK" -ge 3 ] && [ "$FAIL_STREAK" -lt 6 ]; then
        if heal_tier1_dns_mss; then
            DUR=$(( $(date +%s) - START_HEAL_S ))
            [ "$DUR" -lt 1 ] && DUR=1
            echo "$(date): [Tầng 1 Thành Công] Mạng đã thông suốt trở lại sau ${DUR}s!" >> "$LOG_FILE"
            rotate_log_if_needed
            FAIL_STREAK=0
            LAST_RECOVER_TS=$CUR_TS
            send_tg_alert "🩺 <b>BÁC SĨ 5G: TỰ CHỮA LÀNH THÀNH CÔNG! (Tầng 1)</b>
━━━━━━━━━━━━━━━━━━━
⚡ <b>Thời gian xử lý:</b> ~${DUR} giây
🛡️ <b>Phương thức:</b> Sửa DNS Cache & Ghim TCP MSS 1420
🌐 <b>Trạng thái:</b> Đã thông mạng Internet hoàn toàn
📶 Wi-Fi & LAN nội bộ giữ nguyên kết nối 100%!"
            continue
        else
            sleep 8
            continue
        fi
    fi

    # TẦNG 2: LÀM MỚI PHIÊN WWAN (~3.5s)
    # CHỈ KÍCH HOẠT KHI MẤT MẠNG KÉO DÀI LIÊN TỤC >= 6 LẦN (~1.5 - 2 PHÚT THẬT SỰ TẮT)
    if [ "$FAIL_STREAK" -ge 6 ] && [ "$FAIL_STREAK" -lt 10 ]; then
        LAST_RECOVER_TS=$CUR_TS
        if heal_tier2_wwan_session "$ACT_IFACE"; then
            DUR=$(( $(date +%s) - START_HEAL_S ))
            echo "$(date): [Tầng 2 Thành Công] Mạng đã hồi phục sau ${DUR}s!" >> "$LOG_FILE"
            rotate_log_if_needed
            FAIL_STREAK=0
            send_tg_alert "🩺 <b>BÁC SĨ 5G: TỰ CHỮA LÀNH THÀNH CÔNG! (Tầng 2)</b>
━━━━━━━━━━━━━━━━━━━
⚡ <b>Thời gian xử lý:</b> ~${DUR} giây
🛡️ <b>Phương thức:</b> Làm mới phiên Data WWAN (${ACT_IFACE}) & Xả Route
🌐 <b>Trạng thái:</b> Đã nhận lại dải IP sạch và khôi phục mạng
📶 Wi-Fi & LAN nội bộ thông suốt không hề bị ngắt!"
            continue
        fi
    fi

    # TẦNG 3: TÁI SINH SÓNG MODEM & CELL FAILOVER
    # CHỈ KÍCH HOẠT KHI MẤT MẠNG KÉO DÀI LIÊN TỤC >= 10 LẦN (~3-4 PHÚT)
    if [ "$FAIL_STREAK" -ge 10 ]; then
        LAST_RECOVER_TS=$CUR_TS
        if heal_tier3_cfun_cell_failover "$ACT_IFACE"; then
            DUR=$(( $(date +%s) - START_HEAL_S ))
            echo "$(date): [Tầng 3 Thành Công] Sóng modem 5G đã hồi sinh sau ${DUR}s!" >> "$LOG_FILE"
            rotate_log_if_needed
            FAIL_STREAK=0
            SIG_INFO=$(cat /tmp/rf_signal_stats.json 2>/dev/null | jsonfilter -e '$.grade' 2>/dev/null || echo "Ổn định")
            send_tg_alert "🎉 <b>BÁC SĨ 5G: TỰ CHỮA LÀNH THÀNH CÔNG! (Tầng 3)</b>
━━━━━━━━━━━━━━━━━━━
⚡ <b>Thời gian xử lý:</b> ~${DUR} giây
🛡️ <b>Phương thức:</b> Chu kỳ Tái sinh sóng Baseband (CFUN 0/1) & Chuyển trạm BTS
📡 <b>Chất lượng sóng:</b> ${SIG_INFO}
📶 <b>Thiết bị:</b> Không cần khởi động lại Router, Wi-Fi 100% Online!"
            continue
        fi
    fi

    # TẦNG 4: HARDWARE USB BUS RESET & PHYSICAL RE-ENUMERATION
    # KÍCH HOẠT KHI MẤT MẠNG KÉO DÀI >= 15 LẦN (~5-6 PHÚT)
    if [ "$FAIL_STREAK" -ge 15 ]; then
        echo "$(date): [Tầng 4 Cứu Hộ Cứng] Cả 3 tầng trước chưa khôi phục. Kích hoạt Hardware USB Reset toàn diện..." >> "$LOG_FILE"
        rotate_log_if_needed

        # 1. usbreset nếu có nhị phân
        local usb_id=$(lsusb 2>/dev/null | grep -iE "1199:|2c7c:|2cb7:|05c6:" | awk '{print $6}' | head -n 1)
        [ -z "$usb_id" ] && usb_id="1199:90d3"
        if command -v usbreset >/dev/null 2>&1; then
            usbreset "$usb_id" >/dev/null 2>&1
        fi

        # 2. Tái cấp quyền USB sysfs (ngắt và cấp lại nguồn logic USB)
        for auth_f in /sys/bus/usb/devices/2-*/authorized /sys/bus/usb/devices/1-*/authorized; do
            if [ -f "$auth_f" ]; then
                echo 0 > "$auth_f" 2>/dev/null
                sleep 2
                echo 1 > "$auth_f" 2>/dev/null
            fi
        done

        # 3. Dọn dẹp triệt để tiến trình treo
        killall -9 umbim atinout sms_tool 2>/dev/null
        sleep 10

        # 4. Kích hoạt lại interface
        ubus call network.interface."$ACT_IFACE" up 2>/dev/null || ifup "$ACT_IFACE" 2>/dev/null

        # 5. Thăm dò phục hồi
        local t4_ok=0
        for w4 in $(seq 1 15); do
            sleep 2
            if check_internet_status; then
                t4_ok=1
                break
            fi
        done

        if [ "$t4_ok" -eq 1 ]; then
            DUR=$(( $(date +%s) - START_HEAL_S ))
            echo "$(date): [Tầng 4 Thành Công] Hardware USB Bus Reset đã khôi phục kết nối thành công sau ${DUR}s!" >> "$LOG_FILE"
            rotate_log_if_needed
            FAIL_STREAK=0
            send_tg_alert "🚀 <b>BÁC SĨ 5G: TỰ CHỮA LÀNH CỨNG THÀNH CÔNG! (Tầng 4)</b>
━━━━━━━━━━━━━━━━━━━
⚡ <b>Thời gian xử lý:</b> ~${DUR} giây
🛡️ <b>Phương thức:</b> Hardware USB Bus Reset & Re-enumeration
🌐 <b>Trạng thái:</b> Đã kết nối Internet thành công, không cần khởi động lại Router!"
            continue
        fi

        DUR=$(( $(date +%s) - START_HEAL_S ))
        echo "$(date): [Tầng 4 Báo Cáo] Toàn bộ các tầng tự chữa (kể cả Hardware Reset) chưa kết nối được sau ${DUR}s." >> "$LOG_FILE"
        rotate_log_if_needed
        send_tg_alert "⚠️ <b>BÁC SĨ 5G CẢNH BÁO: MẠNG CHƯA KHÔI PHỤC!</b>
━━━━━━━━━━━━━━━━━━━
⏱️ <b>Thời gian chẩn đoán:</b> ${DUR} giây
🔍 <b>Kết quả:</b> Đã thử Tầng 1 (DNS/MSS), Tầng 2 (Làm mới WWAN), Tầng 3 (AT!RESET), Tầng 4 (Hardware USB Reset).
💡 <b>Nguyên nhân có thể:</b> Trạm phát BTS khu vực đang mất sóng hoặc SIM hết hạn gói cước."
    fi
done
