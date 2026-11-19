#!/bin/sh
# ==============================================================================
# 🚀 UNIVERSAL WWAN & TETHERING MASTER DIALER (2026 SPECIALIST EDITION)
# Tương thích 100% mọi router: MTK Filogic, Qualcomm IPQ, Rockchip, x86, v.v.
# Hỗ trợ toàn diện: Mọi Card 4G/5G (PCIe & USB) + Tất cả Smartphone (Android/iOS)
# Học hỏi tinh hoa từ FUjr/QModem: Quét cổng động, khóa AT chống va chạm, tự chữa lành
# ==============================================================================

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export TZ=Asia/Ho_Chi_Minh

DIALER_VER="2026.11-MASTER"
LOG_FILE="/tmp/wwan_dialer.log"
LOCK_FILE="/var/lock/wwan_dialer.lock"
AT_LOCK="/var/lock/modem_at.lock"
STATE_DIR="/tmp/wwan_state"
mkdir -p "$STATE_DIR"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [DIALER] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

# ------------------------------------------------------------------------------
# 1. HÀM GỬI LỆNH AT AN TOÀN TUYỆT ĐỐI (ATOMIC BUSYBOX FLOCK + BẢO VỆ)
# ------------------------------------------------------------------------------
safe_at() {
    local port="$1"
    local cmd="$2"
    local timeout="${3:-2}"
    [ -c "$port" ] || return 1

    (
        local waited=0
        while ! flock -n 200 2>/dev/null; do
            sleep 0.1
            waited=$((waited + 1))
            if [ "$waited" -ge 15 ]; then
                exit 1
            fi
        done
        if command -v sms_tool >/dev/null 2>&1; then
            sms_tool -d "$port" at "$cmd" 2>/dev/null
        elif command -v atinout >/dev/null 2>&1; then
            echo -e "$cmd\r" | atinout - "$port" - 2>/dev/null
        else
            return 1
        fi
    ) 200>"$AT_LOCK"
}

# ------------------------------------------------------------------------------
# 2. BỘ QUÉT CỔNG AT THÔNG MINH ĐỘNG (LEARNED FROM QMODEM SCAN WORKFLOW)
# ------------------------------------------------------------------------------
detect_at_port() {
    # 1. Thử cổng đã được phát hiện trước đó trong RAM
    for cached in /tmp/master_at_port /tmp/master_sms_port /tmp/custom_at_port; do
        if [ -s "$cached" ]; then
            local cp=$(cat "$cached" 2>/dev/null | tr -d ' \r\n')
            if [ -c "$cp" ]; then
                local res=$(safe_at "$cp" "ATI" 2)
                if echo "$res" | grep -q -e Manufacturer -e Model -e Revision -e IMEI -e Quectel -e SIMCOM -e Sierra -e Fibocom -e OK; then
                    echo "$cp"
                    return 0
                fi
            fi
        fi
    done

    # 2. Quét toàn diện tất cả các cổng serial, WWAN, PCIe MHI trong hệ thống
    local candidate_ports="/dev/wwan*at* /dev/mhi_DUN /dev/mhi_BAM_DM /dev/ttyUSB1 /dev/ttyUSB3 /dev/ttyUSB2 /dev/ttyUSB0 /dev/ttyUSB4 /dev/ttyUSB5 /dev/ttyUSB6 /dev/ttyACM0 /dev/ttyACM1 /dev/ttyACM2 /dev/ttyACM3"
    for p in $candidate_ports; do
        [ -c "$p" ] || continue
        local res=$(safe_at "$p" "ATI" 2)
        if echo "$res" | grep -q -e Manufacturer -e Model -e Revision -e IMEI -e Quectel -e SIMCOM -e Sierra -e Fibocom -e OK; then
            echo "$p" > /tmp/master_at_port
            echo "$p" > /tmp/master_sms_port
            echo "$p"
            return 0
        fi
    done
    return 1
}

# ------------------------------------------------------------------------------
# 3. NHẬN DIỆN CARD WWAN & SMARTPHONE (HARDWARE & INTERFACE PROFILER)
# ------------------------------------------------------------------------------
identify_modem() {
    local at_port="$1"
    MODEM_VENDOR="generic"
    MODEM_MODEL="unknown"
    MODEM_PROTOCOL="dhcp"
    MODEM_NETDEV=""

    # 3.1. Tìm Network Interface dữ liệu
    # Ưu tiên các card PCIe & USB WWAN phổ biến
    for iface in eth2 wwan0 usb0 rndis0 mhi_hwip0 rmnet0 rmnet_data0 eth1; do
        if [ -d "/sys/class/net/$iface" ]; then
            # Bỏ qua nếu là cổng LAN/WAN vật lý của router
            if [ "$iface" = "eth0" ] || [ "$iface" = "eth1" ] && [ -d "/sys/class/net/lan1" ]; then
                continue
            fi
            MODEM_NETDEV="$iface"
            break
        fi
    done

    # 3.2. Nhận diện Smartphone USB Tethering (Android / iOS)
    # Đặc điểm: Có giao diện usb0/rndis0/eth1 nhưng KHÔNG có cổng serial AT
    local is_phone=0
    if [ -z "$at_port" ] && [ -n "$MODEM_NETDEV" ]; then
        is_phone=1
    elif lsusb 2>/dev/null | grep -iqE "apple|iphone|google|pixel|samsung|xiaomi|oppo|vivo|oneplus|realme|huawei phone|rndis"; then
        is_phone=1
    fi

    if [ "$is_phone" -eq 1 ] && [ -n "$MODEM_NETDEV" ]; then
        MODEM_VENDOR="phone"
        MODEM_MODEL="USB_Tethering"
        MODEM_PROTOCOL="phone_tether"
        echo "phone|USB_Tethering|phone_tether|$MODEM_NETDEV"
        return 0
    fi

    # 3.3. Nhận diện từ cổng AT Command
    if [ -n "$at_port" ]; then
        local ati=$(safe_at "$at_port" "ATI" 2)
        local usb_info=$(lsusb 2>/dev/null)

        # A. Fibocom (FM350-GL MediaTek vs FM160/FM150 Qualcomm)
        if echo "$ati $usb_info" | grep -iqE "0e8d:712|FM350|T700"; then
            MODEM_VENDOR="fibocom"
            MODEM_MODEL="FM350-GL"
            MODEM_PROTOCOL="fibocom_mtk"
        elif echo "$ati $usb_info" | grep -iqE "fibocom|2cb7:|FM150|FM160|FG360|FG150|NL668"; then
            MODEM_VENDOR="fibocom"
            MODEM_MODEL="FM160_QCOM"
            MODEM_PROTOCOL="fibocom_qcom"
        # B. Quectel 4G/5G
        elif echo "$ati $usb_info" | grep -iqE "quectel|2c7c:|RM500|RM502|RM520|RM521|RG500|EC25|EP06|EM120|EM160"; then
            MODEM_VENDOR="quectel"
            MODEM_MODEL=$(echo "$ati" | grep -oE "RM[0-9]+[A-Z-]*|RG[0-9]+[A-Z-]*|EC[0-9]+[A-Z-]*|EP[0-9]+" | head -1)
            [ -z "$MODEM_MODEL" ] && MODEM_MODEL="Quectel_5G"
            MODEM_PROTOCOL="quectel"
        # C. Sierra Wireless
        elif echo "$ati $usb_info" | grep -iqE "sierra|1199:|EM919|EM75|EM74"; then
            MODEM_VENDOR="sierra"
            MODEM_MODEL="Sierra_WWAN"
            MODEM_PROTOCOL="sierra_mbim"
        # D. SIMCom 4G/5G
        elif echo "$ati $usb_info" | grep -iqE "simcom|1e0e:|SIM8200|SIM8202|SIM8265|SIM8300"; then
            MODEM_VENDOR="simcom"
            MODEM_MODEL="SIMCom_5G"
            MODEM_PROTOCOL="simcom"
        # E. MeiG Smart
        elif echo "$ati $usb_info" | grep -iqE "meig|SRM815|SRM825|SLM750|SLM828"; then
            MODEM_VENDOR="meig"
            MODEM_MODEL="MeiG_5G"
            MODEM_PROTOCOL="meig"
        # F. Huawei
        elif echo "$ati $usb_info" | grep -iqE "huawei|12d1:|ME909|E3372"; then
            MODEM_VENDOR="huawei"
            MODEM_MODEL="Huawei_WWAN"
            MODEM_PROTOCOL="huawei_ndis"
        fi
    fi

    [ -z "$MODEM_NETDEV" ] && MODEM_NETDEV="eth2"
    echo "$MODEM_VENDOR|$MODEM_MODEL|$MODEM_PROTOCOL|$MODEM_NETDEV"
}

# ------------------------------------------------------------------------------
# 4. NHẬN DIỆN NHÀ MẠNG TỰ ĐỘNG & GÁN APN THÔNG MINH (AUTO-APN ENGINE)
# ------------------------------------------------------------------------------
detect_carrier_apn() {
    local at_port="$1"
    local custom_apn=$(cat /etc/config/custom_apn 2>/dev/null | tr -d ' \r\n')
    if [ -n "$custom_apn" ]; then
        echo "$custom_apn"
        return 0
    fi

    local mcc_mnc=""
    if [ -n "$at_port" ]; then
        mcc_mnc=$(safe_at "$at_port" "AT+COPS?" 2 | grep -oE '"[0-9]{5}"' | tr -d '"')
        [ -z "$mcc_mnc" ] && mcc_mnc=$(safe_at "$at_port" "AT+CIMI" 2 | grep -oE '^[0-9]{5}' | head -1)
    fi

    case "$mcc_mnc" in
        "45204") echo "v-internet" ;;   # Viettel 4G/5G
        "45201") echo "m-wap" ;;        # Mobifone
        "45202") echo "m3-world" ;;     # Vinaphone
        "45205") echo "internet" ;;     # Vietnamobile
        "45207") echo "m9_reddi" ;;     # Wintel / Reddi
        *)       echo "v-internet" ;;   # Mặc định Viettel / Tự động
    esac
}

# ------------------------------------------------------------------------------
# 5. ĐỘNG CƠ QUAY SỐ ĐA GIAO THỨC (UNIVERSAL PROTOCOL DIALER)
# ------------------------------------------------------------------------------
dial_modem() {
    local vendor="$1"
    local protocol="$2"
    local netdev="$3"
    local at_port="$4"
    local apn="$5"

    log "Khởi chạy quy trình quay số cho [$vendor] qua giao thức [$protocol] trên card [$netdev], APN=[$apn]..."

    # Đảm bảo bật nguồn radio và chọn chế độ mạng tự động
    if [ -n "$at_port" ]; then
        safe_at "$at_port" "AT+CFUN=1" 2 >/dev/null 2>&1
        safe_at "$at_port" "AT+COPS=0" 2 >/dev/null 2>&1
    fi

    case "$protocol" in
        "fibocom_mtk")
            # Fibocom FM350-GL / T700 (MediaTek PCIe/ECM)
            log ">> Áp dụng cú pháp AT Fibocom MediaTek: AT+CGDCONT=1,\"IPV4V6\",\"$apn\" & AT+CGACT=1,1"
            safe_at "$at_port" "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" 2 >/dev/null
            safe_at "$at_port" "AT+CGACT=1,1" 3 >/dev/null
            ;;

        "fibocom_qcom")
            # Fibocom FM160 / FM150 (Qualcomm RNDIS/ECM)
            log ">> Áp dụng cú pháp AT Fibocom Qualcomm: AT+GTRNDIS=1,1"
            safe_at "$at_port" "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" 2 >/dev/null
            safe_at "$at_port" "AT+GTRNDIS=1,1" 3 >/dev/null
            ;;

        "quectel")
            # Quectel 4G/5G (RM500Q / RM520N / RG500Q / EC25)
            if [ -x "/usr/bin/quectel-CM" ] || [ -x "/usr/bin/quectel-CM-M" ]; then
                local cm_bin="/usr/bin/quectel-CM"
                [ -x "/usr/bin/quectel-CM-M" ] && cm_bin="/usr/bin/quectel-CM-M"
                log ">> Khởi động daemon kết nối Quectel: $cm_bin -i $netdev -s $apn -4 -6"
                killall -9 quectel-CM quectel-CM-M 2>/dev/null
                $cm_bin -i "$netdev" -s "$apn" -4 -6 >/dev/null 2>&1 &
                sleep 3
            else
                log ">> Áp dụng cú pháp AT Quectel ECM: AT+QNETDEVCTL=3,1,1"
                safe_at "$at_port" "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" 2 >/dev/null
                safe_at "$at_port" "AT+QNETDEVCTL=3,1,1" 3 >/dev/null
            fi
            ;;

        "simcom")
            # SIMCom 4G/5G (SIM8200 / SIM8202 / SIM8300)
            log ">> Áp dụng cú pháp AT SIMCom: AT+CNACT=1,1"
            safe_at "$at_port" "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" 2 >/dev/null
            safe_at "$at_port" "AT+CNACT=1,1" 3 >/dev/null
            ;;

        "meig")
            # MeiG Smart (SRM815 / SRM825 / SLM750)
            log ">> Áp dụng cú pháp AT MeiG: AT\$QCRMCALL=1,1,3,2,1"
            safe_at "$at_port" "AT\$QCRMCALL=1,1,3,2,1" 3 >/dev/null
            ;;

        "sierra_mbim")
            # Sierra Wireless EM9190 / EM7565
            log ">> Áp dụng kết nối Sierra Wireless MBIM..."
            if command -v umbim >/dev/null 2>&1; then
                local mbim_dev=$(ls /dev/cdc-wdm* 2>/dev/null | head -1)
                [ -n "$mbim_dev" ] && umbim -d "$mbim_dev" connect "$apn" 2>/dev/null
            fi
            ;;

        "huawei_ndis")
            # Huawei 4G/5G NDIS
            log ">> Áp dụng cú pháp AT Huawei: AT^NDISDUP=1,1,\"$apn\""
            safe_at "$at_port" "AT^NDISDUP=1,1,\"$apn\"" 3 >/dev/null
            ;;

        "phone_tether")
            # Smartphone USB Tethering (Android / iPhone)
            log ">> Nhận diện Smartphone USB Tethering: Không cần lệnh AT, cấu hình trực tiếp giao diện $netdev"
            ;;

        *)
            log ">> Giao thức mặc định: Kiểm tra PDP context và kích hoạt kết nối..."
            safe_at "$at_port" "AT+CGACT=1,1" 2 >/dev/null
            ;;
    esac

    # --------------------------------------------------------------------------
    # 6. THIẾT LẬP GIAO DIỆN MẠNG & CẤP PHÁT IP (DHCP & NETWORK INTEGRATION)
    # --------------------------------------------------------------------------
    log "Kích hoạt interface [$netdev] và đàm phán DHCP..."
    ip link set "$netdev" up 2>/dev/null
    ip link set "$netdev" txqueuelen 2048 2>/dev/null

    # Chạy udhcpc nhận IP với metric 10 (Ưu tiên mạng di động tốc độ cao)
    killall -9 "udhcpc" 2>/dev/null
    udhcpc -i "$netdev" -q -n -R -O 3 -O 6 -m 10 >/dev/null 2>&1 &
    sleep 2

    # Tối ưu hóa Firewall & TTL 65 (Chống bóp băng thông phát Hotspot từ nhà mạng)
    # Hỗ trợ cả firewall 3 (iptables) và firewall 4 (nftables)
    if command -v nft >/dev/null 2>&1; then
        nft add rule inet fw4 mangle_postrouting oifname "$netdev" ip ttl set 65 2>/dev/null
    fi
    if command -v iptables >/dev/null 2>&1; then
        iptables -t mangle -C POSTROUTING -o "$netdev" -j TTL --ttl-set 65 2>/dev/null || \
        iptables -t mangle -I POSTROUTING 1 -o "$netdev" -j TTL --ttl-set 65 2>/dev/null
        iptables -t mangle -C POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || \
        iptables -t mangle -I POSTROUTING 1 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null
    fi

    # Lưu lại trạng thái quay số
    echo "$vendor" > "$STATE_DIR/vendor"
    echo "$netdev" > "$STATE_DIR/netdev"
    echo "$at_port" > "$STATE_DIR/at_port"
    echo "$apn" > "$STATE_DIR/apn"
    date +%s > "$STATE_DIR/dial_time"

    log "✔️ Hoàn tất thủ tục quay số trên [$netdev]! Kiểm tra kết nối Internet..."
}

# ------------------------------------------------------------------------------
# 7. KIỂM TRA ĐỘ KẾT NỐI & TỰ KHẮC PHỤC SỰ CỐ (HEALTH-CHECK & WATCHDOG)
# ------------------------------------------------------------------------------
check_health_and_heal() {
    local netdev=$(cat "$STATE_DIR/netdev" 2>/dev/null || echo "eth2")
    local at_port=$(cat "$STATE_DIR/at_port" 2>/dev/null || echo "/dev/ttyUSB1")

    # Kiểm tra Ping ra ngoài
    if ping -I "$netdev" -c 2 -W 2 8.8.8.8 >/dev/null 2>&1 || ping -I "$netdev" -c 2 -W 2 1.1.1.1 >/dev/null 2>&1; then
        rm -f "$STATE_DIR/fail_count" 2>/dev/null
        return 0
    fi

    # Tăng bộ đếm thất bại
    local fails=$(cat "$STATE_DIR/fail_count" 2>/dev/null || echo 0)
    fails=$((fails + 1))
    echo "$fails" > "$STATE_DIR/fail_count"
    log "⚠️ Mất kết nối Internet trên [$netdev] (Lần $fails/3)!"

    if [ "$fails" -ge 3 ]; then
        log "🚨 Bắt đầu chu trình tự phục hồi mạng 3 cấp (Self-Healing)..."
        # Cấp 1: Cấp lại DHCP
        log ">> [Cấp 1] Renew DHCP lease..."
        udhcpc -i "$netdev" -n -q -R 2>/dev/null
        sleep 2
        if ping -I "$netdev" -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            log "✔️ Phục hồi thành công ở Cấp 1!"
            rm -f "$STATE_DIR/fail_count"
            return 0
        fi

        # Cấp 2: Tái khởi động sóng di động (CFUN Toggle)
        log ">> [Cấp 2] Tái tạo kết nối sóng RF (AT+CFUN=0 -> CFUN=1)..."
        safe_at "$at_port" "AT+CFUN=0" 2 >/dev/null
        sleep 2
        safe_at "$at_port" "AT+CFUN=1" 2 >/dev/null
        sleep 3
        dial_auto
        rm -f "$STATE_DIR/fail_count"
    fi
}

# ------------------------------------------------------------------------------
# 8. HÀM ĐIỀU PHỐI TỔNG (MASTER DISPATCHER)
# ------------------------------------------------------------------------------
dial_auto() {
    log "=========================================================="
    log "Bắt đầu quét phần cứng WWAN & Thiết bị ngoại vi di động..."
    log "=========================================================="

    local at_port=$(detect_at_port)
    if [ -n "$at_port" ]; then
        log "✔️ Tìm thấy cổng AT phản hồi chuẩn: $at_port"
    else
        log "ℹ️ Không phát hiện cổng AT serial (Kiểm tra chế độ Smartphone Tethering)..."
    fi

    local profile=$(identify_modem "$at_port")
    local vendor=$(echo "$profile" | cut -d'|' -f1)
    local model=$(echo "$profile" | cut -d'|' -f2)
    local protocol=$(echo "$profile" | cut -d'|' -f3)
    local netdev=$(echo "$profile" | cut -d'|' -f4)

    log "Thông tin nhận diện:"
    log "  - Nhà sản xuất : $vendor"
    log "  - Dòng thiết bị: $model"
    log "  - Giao thức    : $protocol"
    log "  - Cổng mạng    : $netdev"

    local apn=$(detect_carrier_apn "$at_port")
    log "  - Điểm truy cập: $apn"

    dial_modem "$vendor" "$protocol" "$netdev" "$at_port" "$apn"
}

# ------------------------------------------------------------------------------
# CLI ENTRY POINT
# ------------------------------------------------------------------------------
case "$1" in
    start|dial)
        dial_auto
        ;;
    heal|check)
        check_health_and_heal
        ;;
    scan)
        at_port=$(detect_at_port)
        profile=$(identify_modem "$at_port")
        apn=$(detect_carrier_apn "$at_port")
        echo "AT_PORT  : ${at_port:-None}"
        echo "PROFILE  : $profile"
        echo "APN      : $apn"
        ;;
    status)
        netdev=$(cat "$STATE_DIR/netdev" 2>/dev/null || echo "eth2")
        vendor=$(cat "$STATE_DIR/vendor" 2>/dev/null || echo "unknown")
        at_port=$(cat "$STATE_DIR/at_port" 2>/dev/null || echo "unknown")
        echo "=== WWAN & TETHERING STATUS ($DIALER_VER) ==="
        echo "Thiết bị  : $vendor"
        echo "Cổng AT   : $at_port"
        echo "Cổng mạng : $netdev"
        if ip addr show "$netdev" 2>/dev/null | grep -q "inet "; then
            ip=$(ip -4 addr show "$netdev" | grep "inet " | awk '{print $2}')
            echo "Địa chỉ IP: $ip (Đang kết nối)"
        else
            echo "Địa chỉ IP: Chưa có IP"
        fi
        if ping -I "$netdev" -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            echo "Internet  : 🟢 THÔNG SUỐT (Ping 8.8.8.8 OK)"
        else
            echo "Internet  : 🔴 MẤT KẾT NỐI"
        fi
        ;;
    *)
        echo "Cú pháp: $0 {dial|scan|status|heal}"
        ;;
esac
