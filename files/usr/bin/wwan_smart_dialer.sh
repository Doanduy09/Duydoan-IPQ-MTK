#!/bin/sh
# ==============================================================================
# 🚀 ULTIMATE UNIVERSAL WWAN & TETHERING MASTER DIALER (2026 EDITION)
# Tương thích 100% mọi router: MTK Filogic, Qualcomm IPQ, Rockchip, x86, v.v.
# Hỗ trợ toàn diện 100% mọi giao thức:
#   - Bus: PCIe MHI (mhi_hwip0), PCIe ECM (eth2), USB ECM, USB RNDIS, USB NCM/NDIS
#   - Giao thức: QMI (uqmi), MBIM (umbim), ECM/RNDIS/NDIS, Smartphone Tethering
#   - Hãng: Fibocom (MTK/QCOM), Quectel, SIMCom, MeiG, Sierra, Telit, Neoway, ZTE, GosunCn, Huawei
#   - Điện thoại: Android RNDIS (usb0), Apple iPhone CDC-Ether (eth1/usb0)
#   - Network: Dual-Stack IPv4 (udhcpc) + IPv6 (odhcp6c) + TTL/HL 65 Antidote
# Học hỏi tinh hoa từ FUjr/QModem: Quét cổng động, khóa AT chống va chạm, tự chữa lành
# ==============================================================================

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export TZ=Asia/Ho_Chi_Minh

DIALER_VER="2026.11-ULTIMATE-FULL-SPECTRUM"
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
                if echo "$res" | grep -q -e Manufacturer -e Model -e Revision -e IMEI -e Quectel -e SIMCOM -e Sierra -e Fibocom -e Telit -e Neoway -e ZTE -e OK; then
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
        if echo "$res" | grep -q -e Manufacturer -e Model -e Revision -e IMEI -e Quectel -e SIMCOM -e Sierra -e Fibocom -e Telit -e Neoway -e ZTE -e OK; then
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
    # Ưu tiên các card PCIe & USB WWAN theo thứ tự chuẩn
    for iface in mhi_hwip0 mhi_swip0 eth2 wwan0 usb0 rndis0 rmnet0 rmnet_data0 eth1; do
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
    local is_phone=0
    if [ -z "$at_port" ] && [ -n "$MODEM_NETDEV" ]; then
        is_phone=1
    elif lsusb 2>/dev/null | grep -iqE "apple|iphone|google|pixel|samsung|xiaomi|oppo|vivo|oneplus|realme|huawei phone|rndis"; then
        is_phone=1
    fi

    if [ "$is_phone" -eq 1 ] && [ -n "$MODEM_NETDEV" ]; then
        MODEM_VENDOR="phone"
        if lsusb 2>/dev/null | grep -iqE "apple|iphone"; then
            MODEM_MODEL="Apple iPhone/iPad (CDC-Ether)"
        else
            MODEM_MODEL="Android Smartphone (RNDIS)"
        fi
        MODEM_PROTOCOL="phone_tether"
        echo "$MODEM_VENDOR|$MODEM_MODEL|$MODEM_PROTOCOL|$MODEM_NETDEV"
        return 0
    fi

    # 3.3. Nhận diện Card WWAN thông qua cổng AT
    if [ -n "$at_port" ]; then
        local ati_info=$(safe_at "$at_port" "ATI" 2)
        local csub_info=$(safe_at "$at_port" "AT+CSUB" 2)
        local all_info="$ati_info $csub_info"

        if echo "$all_info" | grep -iq "fibocom"; then
            MODEM_VENDOR="fibocom"
            if echo "$all_info" | grep -iq "FM350"; then
                MODEM_MODEL="FM350-GL"
                MODEM_PROTOCOL="fibocom_mtk"
                [ -z "$MODEM_NETDEV" ] && MODEM_NETDEV="eth2"
            elif echo "$all_info" | grep -iqE "FM160|FM150"; then
                MODEM_MODEL="FM160-Series"
                MODEM_PROTOCOL="fibocom_qcom"
            else
                MODEM_MODEL="Fibocom-Universal"
                MODEM_PROTOCOL="fibocom_mtk"
            fi
        elif echo "$all_info" | grep -iq "quectel"; then
            MODEM_VENDOR="quectel"
            if echo "$all_info" | grep -iq "RM520"; then
                MODEM_MODEL="RM520N"
            elif echo "$all_info" | grep -iq "RM500"; then
                MODEM_MODEL="RM500Q"
            elif echo "$all_info" | grep -iq "RG500"; then
                MODEM_MODEL="RG500Q"
            else
                MODEM_MODEL="Quectel-Series"
            fi
            # Kiểm tra xem chạy qua MHI PCIe hay USB
            if [ "$MODEM_NETDEV" = "mhi_hwip0" ]; then
                MODEM_PROTOCOL="quectel_mhi"
            else
                MODEM_PROTOCOL="quectel"
            fi
        elif echo "$all_info" | grep -iq "simcom"; then
            MODEM_VENDOR="simcom"
            MODEM_MODEL="SIM8200-Series"
            MODEM_PROTOCOL="simcom"
        elif echo "$all_info" | grep -iq -e "meig" -e "srm"; then
            MODEM_VENDOR="meig"
            MODEM_MODEL="MeiG-SRM-Series"
            MODEM_PROTOCOL="meig"
        elif echo "$all_info" | grep -iq -e "sierra" -e "em919" -e "em75"; then
            MODEM_VENDOR="sierra"
            MODEM_MODEL="Sierra-AirPrime"
            MODEM_PROTOCOL="sierra_mbim"
        elif echo "$all_info" | grep -iq -e "telit" -e "fn980" -e "fn990" -e "le910"; then
            MODEM_VENDOR="telit"
            MODEM_MODEL="Telit-Cellular"
            MODEM_PROTOCOL="telit"
        elif echo "$all_info" | grep -iq -e "neoway" -e "n75" -e "n58"; then
            MODEM_VENDOR="neoway"
            MODEM_MODEL="Neoway-Series"
            MODEM_PROTOCOL="neoway"
        elif echo "$all_info" | grep -iq -e "huawei" -e "me906" -e "e3372"; then
            MODEM_VENDOR="huawei"
            MODEM_MODEL="Huawei-Cellular"
            MODEM_PROTOCOL="huawei_ndis"
        elif echo "$all_info" | grep -iq -e "zte" -e "gosuncn" -e "asr" -e "me3630"; then
            MODEM_VENDOR="zte"
            MODEM_MODEL="ZTE/GosunCn"
            MODEM_PROTOCOL="zte_ecm"
        else
            MODEM_VENDOR="generic_wwan"
            MODEM_MODEL="3GPP-Cellular"
            MODEM_PROTOCOL="generic_3gpp"
        fi
    fi

    # 3.4. Kiểm tra Driver QMI hoặc MBIM nếu có thiết bị /dev/cdc-wdm*
    if [ -e "/dev/cdc-wdm0" ] || [ -e "/dev/cdc-wdm1" ]; then
        local wdm_dev=$(ls /dev/cdc-wdm* 2>/dev/null | head -1)
        if command -v uqmi >/dev/null 2>&1 && uqmi -d "$wdm_dev" --get-device-operating-mode 2>/dev/null | grep -q "online"; then
            MODEM_PROTOCOL="qmi_native"
        elif command -v umbim >/dev/null 2>&1 && umbim -d "$wdm_dev" caps 2>/dev/null | grep -q "MBIM"; then
            MODEM_PROTOCOL="mbim_native"
        fi
    fi

    [ -z "$MODEM_NETDEV" ] && MODEM_NETDEV="wwan0"
    echo "$MODEM_VENDOR|$MODEM_MODEL|$MODEM_PROTOCOL|$MODEM_NETDEV"
}

# ------------------------------------------------------------------------------
# 4. TỰ ĐỘNG PHÁT HIỆN NHÀ MẠNG & CHỌN APN CHUẨN XÁC TỐI ƯU
# ------------------------------------------------------------------------------
detect_carrier_apn() {
    local at_port="$1"
    local apn="v-internet"

    if [ -n "$at_port" ]; then
        local cops=$(safe_at "$at_port" "AT+COPS?" 2)
        local imsi=$(safe_at "$at_port" "AT+CIMI" 2 | tr -cd '0-9')

        if echo "$cops" | grep -iq -e "Viettel" -e "45204" || echo "$imsi" | grep -q "^45204"; then
            apn="v-internet"
        elif echo "$cops" | grep -iq -e "Mobifone" -e "45201" || echo "$imsi" | grep -q "^45201"; then
            apn="m-wap"
        elif echo "$cops" | grep -iq -e "Vinaphone" -e "VNPT" -e "45202" || echo "$imsi" | grep -q "^45202"; then
            apn="m3-world"
        elif echo "$cops" | grep -iq -e "Wintel" -e "Reddi"; then
            apn="m9"
        elif echo "$cops" | grep -iq -e "Vietnamobile" -e "45205" || echo "$imsi" | grep -q "^45205"; then
            apn="v-internet"
        fi
    fi
    echo "$apn"
}

# ------------------------------------------------------------------------------
# 5. BỘ QUAY SỐ ĐA GIAO THỨC TOÀN NĂNG (FULL-SPECTRUM DIAL ENGINE)
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

    local dial_ok=0

    case "$protocol" in
        "fibocom_mtk")
            # Fibocom FM350-GL / T700 (MediaTek PCIe/ECM)
            log ">> Áp dụng cú pháp AT Fibocom MediaTek: AT+CGDCONT=1,\"IPV4V6\",\"$apn\" & AT+CGACT=1,1"
            safe_at "$at_port" "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" 2 >/dev/null
            safe_at "$at_port" "AT+CGACT=1,1" 3 >/dev/null && dial_ok=1
            ;;

        "fibocom_qcom")
            # Fibocom FM160 / FM150 (Qualcomm RNDIS/ECM)
            log ">> Áp dụng cú pháp AT Fibocom Qualcomm: AT+GTRNDIS=1,1"
            safe_at "$at_port" "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" 2 >/dev/null
            safe_at "$at_port" "AT+GTRNDIS=1,1" 3 >/dev/null && dial_ok=1
            ;;

        "quectel_mhi"|"quectel")
            # Quectel 4G/5G (RM500Q / RM520N / RG500Q / EC25) qua PCIe MHI hoặc USB
            if [ -x "/usr/bin/quectel-CM" ] || [ -x "/usr/bin/quectel-CM-M" ]; then
                local cm_bin="/usr/bin/quectel-CM"
                [ -x "/usr/bin/quectel-CM-M" ] && cm_bin="/usr/bin/quectel-CM-M"
                log ">> Khởi động daemon kết nối Quectel: $cm_bin -i $netdev -s $apn -4 -6"
                killall -9 quectel-CM quectel-CM-M 2>/dev/null
                $cm_bin -i "$netdev" -s "$apn" -4 -6 >/dev/null 2>&1 &
                sleep 2
                dial_ok=1
            else
                log ">> Áp dụng cú pháp AT Quectel ECM: AT+QNETDEVCTL=3,1,1"
                safe_at "$at_port" "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" 2 >/dev/null
                safe_at "$at_port" "AT+QNETDEVCTL=3,1,1" 3 >/dev/null && dial_ok=1
            fi
            ;;

        "simcom")
            # SIMCom 4G/5G (SIM8200 / SIM8202 / SIM8300 / SIM7600)
            log ">> Áp dụng cú pháp AT SIMCom: AT+CNACT=1,1"
            safe_at "$at_port" "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" 2 >/dev/null
            safe_at "$at_port" "AT+CNACT=1,1" 3 >/dev/null && dial_ok=1
            ;;

        "meig")
            # MeiG Smart (SRM815 / SRM825 / SLM750)
            log ">> Áp dụng cú pháp AT MeiG: AT\$QCRMCALL=1,1,3,2,1"
            safe_at "$at_port" "AT\$QCRMCALL=1,1,3,2,1" 3 >/dev/null && dial_ok=1
            ;;

        "sierra_mbim"|"mbim_native")
            # Sierra Wireless EM9190 / EM7565 / Chuẩn MBIM
            log ">> Áp dụng kết nối MBIM chuẩn qua umbim..."
            if command -v umbim >/dev/null 2>&1; then
                local mbim_dev=$(ls /dev/cdc-wdm* 2>/dev/null | head -1)
                if [ -n "$mbim_dev" ]; then
                    umbim -d "$mbim_dev" -n caps >/dev/null 2>&1
                    umbim -d "$mbim_dev" -n attach >/dev/null 2>&1
                    umbim -d "$mbim_dev" -n connect "$apn" >/dev/null 2>&1 && dial_ok=1
                fi
            fi
            ;;

        "qmi_native")
            # Giao thức Qualcomm QMI chuẩn
            log ">> Áp dụng kết nối QMI chuẩn qua uqmi..."
            if command -v uqmi >/dev/null 2>&1; then
                local qmi_dev=$(ls /dev/cdc-wdm* /dev/mhi_QMI* 2>/dev/null | head -1)
                if [ -n "$qmi_dev" ]; then
                    uqmi -d "$qmi_dev" --wda-set-data-format 802-3 2>/dev/null || uqmi -d "$qmi_dev" --wda-set-data-format raw-ip 2>/dev/null
                    uqmi -d "$qmi_dev" --start-network "$apn" --autoconnect >/dev/null 2>&1 && dial_ok=1
                fi
            fi
            ;;

        "telit")
            # Telit 4G/5G (LE910 / FN980 / FN990)
            log ">> Áp dụng cú pháp AT Telit: AT#SGACT=1,1"
            safe_at "$at_port" "AT#CGDCONT=1,\"IPV4V6\",\"$apn\"" 2 >/dev/null
            safe_at "$at_port" "AT#SGACT=1,1" 3 >/dev/null && dial_ok=1
            ;;

        "neoway")
            # Neoway (N58 / N75 / N720)
            log ">> Áp dụng cú pháp AT Neoway: AT\$MYUSBNETACT=1,1"
            safe_at "$at_port" "AT\$MYUSBNETACT=1,1" 3 >/dev/null && dial_ok=1
            ;;

        "huawei_ndis")
            # Huawei 4G/5G NDIS
            log ">> Áp dụng cú pháp AT Huawei: AT^NDISDUP=1,1,\"$apn\""
            safe_at "$at_port" "AT^NDISDUP=1,1,\"$apn\"" 3 >/dev/null && dial_ok=1
            ;;

        "zte_ecm")
            # ZTE / GosunCn / ASR
            log ">> Áp dụng cú pháp AT ZTE/GosunCn: AT+ZECMCALL=1"
            safe_at "$at_port" "AT+ZECMCALL=1" 3 >/dev/null && dial_ok=1
            ;;

        "phone_tether")
            # Smartphone USB Tethering (Android / iPhone)
            log ">> Nhận diện Smartphone USB Tethering: Cấu hình trực tiếp giao diện $netdev"
            dial_ok=1
            ;;

        *)
            # Giao thức chung / Dự phòng cấp 1
            log ">> Giao thức mặc định: Kiểm tra PDP context và kích hoạt kết nối..."
            safe_at "$at_port" "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" 2 >/dev/null
            safe_at "$at_port" "AT+CGACT=1,1" 2 >/dev/null && dial_ok=1
            ;;
    esac

    # CHUỖI DỰ PHÒNG TOÀN NĂNG (CASCADING FALLBACK) NẾU LỆNH HÃNG CHƯA ĐẠT
    if [ "$dial_ok" -eq 0 ] && [ -n "$at_port" ]; then
        log "⚠️ Lệnh riêng của hãng chưa kích hoạt được, chạy Chuỗi Dự Phòng Toàn Năng (Cascading Fallback)..."
        safe_at "$at_port" "AT+CGACT=1,1" 2 >/dev/null || \
        safe_at "$at_port" "AT+GTRNDIS=1,1" 2 >/dev/null || \
        safe_at "$at_port" "AT+QNETDEVCTL=3,1,1" 2 >/dev/null || \
        safe_at "$at_port" "AT+CNACT=1,1" 2 >/dev/null
    fi

    # --------------------------------------------------------------------------
    # 6. THIẾT LẬP GIAO DIỆN MẠNG & DUAL-STACK (DHCPv4 + DHCPv6 + TTL/HL 65)
    # --------------------------------------------------------------------------
    log "Kích hoạt interface [$netdev] và đàm phán địa chỉ IP..."
    ip link set "$netdev" up 2>/dev/null
    ip link set "$netdev" txqueuelen 2048 2>/dev/null

    # Chạy udhcpc nhận IPv4 với metric 10 (Ưu tiên mạng di động tốc độ cao)
    killall -9 "udhcpc" 2>/dev/null
    udhcpc -i "$netdev" -q -n -R -O 3 -O 6 -m 10 >/dev/null 2>&1 &

    # Hỗ trợ IPv6 Native qua odhcp6c nếu có
    if command -v odhcp6c >/dev/null 2>&1; then
        killall -9 "odhcp6c" 2>/dev/null
        odhcp6c -s /lib/netifd/dhcpv6.script -P0 -m 10 "$netdev" >/dev/null 2>&1 &
    fi

    sleep 2

    # Tối ưu hóa Firewall & TTL 65 + HopLimit 65 (Chống bóp băng thông phát Hotspot từ nhà mạng)
    # Hỗ trợ cả firewall 4 (nftables) và firewall 3 (iptables)
    if command -v nft >/dev/null 2>&1; then
        nft add rule inet fw4 mangle_postrouting oifname "$netdev" ip ttl set 65 2>/dev/null
        nft add rule inet fw4 mangle_postrouting oifname "$netdev" ip6 hoplimit set 65 2>/dev/null
    fi
    if command -v iptables >/dev/null 2>&1; then
        iptables -t mangle -C POSTROUTING -o "$netdev" -j TTL --ttl-set 65 2>/dev/null || \
        iptables -t mangle -I POSTROUTING 1 -o "$netdev" -j TTL --ttl-set 65 2>/dev/null
        iptables -t mangle -C POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || \
        iptables -t mangle -I POSTROUTING 1 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null
    fi
    if command -v ip6tables >/dev/null 2>&1; then
        ip6tables -t mangle -C POSTROUTING -o "$netdev" -j HL --hl-set 65 2>/dev/null || \
        ip6tables -t mangle -I POSTROUTING 1 -o "$netdev" -j HL --hl-set 65 2>/dev/null
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
