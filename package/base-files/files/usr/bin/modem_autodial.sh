#!/bin/sh
# ==============================================================================
# 🚀 UNIVERSAL PCIE & USB 5G/LTE MULTI-CARD AUTO-DIAL ENGINE (HỆ THỐNG QUAY SỐ ĐA NĂNG)
# Tương thích 100% mọi dòng card WWAN PCIe & USB trên OpenWrt:
#   1. Qualcomm Snapdragon 5G PCIe (SDX55 / SDX62 / SDX65 / SDX75)
#      - Sierra Wireless (EM9190, EM9191, EM9291)
#      - Quectel (RM500Q-AE/GL, RM520N-GL, RM530N-GL, RG500Q)
#      - Fibocom (FM150, FM160, FG150, FG360)
#      - Telit (FN980, FN990), SIMCom (SIM8200EA, SIM8202G), Foxconn (T99W175, T99W373)
#      - Hỗ trợ cả 2 driver: Qualcomm NSS rmnet (pcie_mhi / mhi_q) & Upstream Linux (mhi_pci_generic)
#   2. MediaTek 5G PCIe (T750 / T830)
#      - Fibocom FM350-GL, Intel 5000 (Driver: mtk_t7xx -> mbim / wwan0)
#   3. Intel XMM LTE/5G PCIe (XMM7360 / XMM7560)
#      - Fibocom L850-GL, L860-GL (Driver: iosm -> mbim / wwan0)
#   4. Mọi dòng Card USB / Dongle 4G/5G (QMI, MBIM, XMM, Quectel, ECM, RNDIS)
# ==============================================================================

LOG_TAG="[MODEM_AUTODIAL]"
log() {
    echo "$LOG_TAG $*"
    logger -t "modem_autodial" "$*" 2>/dev/null
}

# --- CÁC BIẾN TRẠNG THÁI ---
MODEM_NAME=""
MODEM_BUS="unknown"
MODEM_DRIVER=""
IFACE="Modem"
NET_DEV=""
CTRL_DEV=""
AT_PORT=""
PROTO=""
APN="v-internet"

# Helper gửi lệnh AT đa kênh (Hỗ trợ sms_tool, atinout, gcom, hoặc direct IO)
send_at() {
    local port="$1"
    local cmd="$2"
    [ ! -c "$port" ] && return 1

    if command -v sms_tool >/dev/null 2>&1; then
        sms_tool -D -d "$port" at "$cmd" 2>/dev/null
    elif command -v atinout >/dev/null 2>&1; then
        echo "$cmd" | timeout 3 atinout - "$port" - 2>/dev/null
    elif command -v gcom >/dev/null 2>&1; then
        printf 'send "%s\\r"\nwait 1 "OK"\n' "$cmd" | timeout 3 gcom -d "$port" -s /dev/stdin 2>/dev/null
    else
        # Direct raw serial fallback
        (
            stty -F "$port" 115200 raw -echo 2>/dev/null
            exec 3<>"$port"
            printf "%s\r\n" "$cmd" >&3
            timeout 2 head -n 10 <&3
            exec 3>&-
        ) 2>/dev/null
    fi
}

# ------------------------------------------------------------------------------
# BƯỚC 1: KHẢO SÁT TOÀN BỘ PHẦN CỨNG PCIE & USB TRÊN ROUTER
# ------------------------------------------------------------------------------
discover_hardware() {
    # 1.1 Quét bus PCIe tìm Card WWAN (Vendor IDs: Qualcomm 17cb, Quectel 2c7c, Sierra 1199, Fibocom 2cb7, Telit 1bc7, SIMCom 1eac, Foxconn 14c0/105b, MediaTek 0e8d, Intel 8086)
    for devpath in /sys/bus/pci/devices/*; do
        [ ! -d "$devpath" ] && continue
        vendor=$(cat "$devpath/vendor" 2>/dev/null | tr '[:upper:]' '[:lower:]')
        device=$(cat "$devpath/device" 2>/dev/null | tr '[:upper:]' '[:lower:]')
        pclass=$(cat "$devpath/class" 2>/dev/null | tr '[:upper:]' '[:lower:]')
        driver_link=$(readlink "$devpath/driver" 2>/dev/null)
        driver_name=$(basename "$driver_link" 2>/dev/null)

        case "$vendor" in
            0x17cb|0x2c7c|0x1199|0x2cb7|0x1bc7|0x1eac|0x14c0|0x105b|0x2949|0x0e8d|0x8086)
                MODEM_BUS="pcie"
                MODEM_DRIVER="$driver_name"
                case "$vendor" in
                    0x17cb) MODEM_NAME="Qualcomm Snapdragon 5G PCIe (SDX Series)" ;;
                    0x2c7c) MODEM_NAME="Quectel 5G PCIe (RM500Q/RM520N/RM530N)" ;;
                    0x1199) MODEM_NAME="Sierra Wireless 5G PCIe (EM9190/EM9291)" ;;
                    0x2cb7) MODEM_NAME="Fibocom 5G/LTE PCIe (FM160/FM350/L850)" ;;
                    0x1bc7) MODEM_NAME="Telit 5G PCIe (FN980/FN990)" ;;
                    0x1eac) MODEM_NAME="SIMCom 5G PCIe (SIM8200/SIM8202)" ;;
                    0x0e8d) MODEM_NAME="MediaTek 5G PCIe (T750/T830)" ;;
                    0x8086) MODEM_NAME="Intel 5G/LTE PCIe" ;;
                    *) MODEM_NAME="Generic WWAN PCIe ($vendor:$device)" ;;
                esac
                break
                ;;
        esac
    done

    # 1.2 Dò tìm cổng AT chuyên dụng trên PCIe hoặc USB
    for p in /dev/mhi_DUN /dev/mhi_*_DUN /dev/mhi_at0 /dev/wwan0at0 /dev/wwan*at* /dev/ttyUSB2 /dev/ttyUSB1 /dev/ttyUSB0 /dev/ttyACM0; do
        if [ -c "$p" ]; then
            AT_PORT="$p"
            break
        fi
    done

    # 1.3 Phân loại Kiến trúc quay số dựa trên Driver và Card mạng
    # Nhánh A: Qualcomm NSS Acceleration (pcie_mhi / mhi_q với rmnet_mhi0)
    if [ -d "/sys/bus/pci/drivers/pcie_mhi" ] || [ -d "/sys/bus/pci/drivers/mhi_q" ] || [ -d "/sys/class/net/rmnet_mhi0" ] || [ -c "/dev/mhi_DUN" ]; then
        MODEM_BUS="pcie"
        PROTO="pcie_nss"
        NET_DEV="rmnet_mhi0.1"
        CTRL_DEV="/dev/mhi_DUN"
        [ ! -c "$CTRL_DEV" ] && CTRL_DEV="/dev/mhi_QMI0"
        [ -z "$MODEM_NAME" ] && MODEM_NAME="Qualcomm SDX55/SDX65 (pcie_mhi + NSS rmnet)"

    # Nhánh B: MediaTek PCIe (mtk_t7xx - Fibocom FM350-GL)
    elif [ -d "/sys/bus/pci/drivers/mtk_t7xx" ] || [ -c "/dev/wwan0mbim0" -a -c "/dev/wwan0at0" ]; then
        MODEM_BUS="pcie"
        PROTO="mbim"
        NET_DEV="wwan0"
        CTRL_DEV="/dev/wwan0mbim0"
        [ -z "$AT_PORT" ] && AT_PORT="/dev/wwan0at0"
        [ -z "$MODEM_NAME" ] && MODEM_NAME="Fibocom FM350-GL 5G (PCIe mtk_t7xx)"

    # Nhánh C: Upstream Linux Generic MHI WWAN (mhi_pci_generic / mhi_wwan_mbim / mhi_wwan_qmi)
    elif [ -d "/sys/bus/mhi" ] || [ -d "/sys/bus/pci/drivers/mhi_pci_generic" ]; then
        MODEM_BUS="pcie"
        if [ -c "/dev/wwan0mbim0" ] || [ -c "/dev/mhi_MBIM" ]; then
            PROTO="mbim"
            NET_DEV="wwan0"
            CTRL_DEV="/dev/wwan0mbim0"
            [ ! -c "$CTRL_DEV" ] && CTRL_DEV="/dev/mhi_MBIM"
        else
            PROTO="qmi"
            NET_DEV="wwan0"
            CTRL_DEV="/dev/wwan0qmi0"
            [ ! -c "$CTRL_DEV" ] && CTRL_DEV="/dev/mhi_QMI0"
        fi
        [ -z "$MODEM_NAME" ] && MODEM_NAME="Qualcomm 5G PCIe (Generic Linux MHI)"

    # Nhánh D: Intel XMM / IOSM PCIe (Fibocom L850-GL/L860-GL)
    elif [ -d "/sys/bus/pci/drivers/iosm" ] || [ -d "/sys/class/net/iosm0" ]; then
        MODEM_BUS="pcie"
        PROTO="mbim"
        NET_DEV="wwan0"
        [ -d "/sys/class/net/iosm0" ] && NET_DEV="iosm0"
        CTRL_DEV="/dev/wwan0mbim0"
        [ -z "$MODEM_NAME" ] && MODEM_NAME="Intel XMM PCIe (iosm)"

    # Nhánh E: USB Fibocom FM350-GL XMM Mode
    elif lsusb 2>/dev/null | grep -iqE "0e8d:7127|fm350" || [ -c "/dev/ttyUSB3" -a -f "/lib/netifd/proto/xmm.sh" ]; then
        MODEM_BUS="usb"
        PROTO="xmm"
        NET_DEV="wwan0"
        CTRL_DEV="/dev/ttyUSB3"
        AT_PORT="/dev/ttyUSB1"
        MODEM_NAME="Fibocom FM350-GL 5G (USB XMM)"

    # Nhánh F: USB CDC-WDM (Quectel / Sierra / Telit / SIMCom USB)
    elif [ -c "/dev/cdc-wdm0" ]; then
        MODEM_BUS="usb"
        NET_DEV="wwan0"
        CTRL_DEV="/dev/cdc-wdm0"
        if lsusb 2>/dev/null | grep -iqE "2c7c:|quectel"; then
            PROTO="quectel"
            MODEM_NAME="Quectel 5G/LTE USB"
        else
            PROTO="mbim"
            MODEM_NAME="Generic CDC-WDM MBIM USB"
        fi

    # Nhánh G: USB RNDIS / ECM / NCM (usb0 hoặc eth2)
    elif [ -d "/sys/class/net/usb0" ] || [ -d "/sys/class/net/eth2" ]; then
        MODEM_BUS="usb"
        PROTO="dhcp"
        NET_DEV="usb0"
        [ ! -d "/sys/class/net/usb0" ] && NET_DEV="eth2"
        MODEM_NAME="USB Tethering / RNDIS / ECM"
    else
        log "Chưa phát hiện thiết bị WWAN PCIe hoặc USB nào."
        return 1
    fi

    log "Phát hiện phần cứng: $MODEM_NAME (Bus: $MODEM_BUS, Driver: $MODEM_DRIVER, Proto: $PROTO, Net: $NET_DEV, Ctrl: $CTRL_DEV, AT: $AT_PORT)"
    echo "$MODEM_NAME" > /tmp/master_m_type
    [ -n "$AT_PORT" ] && echo "$AT_PORT" > /tmp/master_sms_port
    [ -n "$AT_PORT" ] && echo "$AT_PORT" > /tmp/custom_at_port
    return 0
}

# ------------------------------------------------------------------------------
# BƯỚC 2: KIỂM TRA TRẠNG THÁI SIM & TỰ ĐỘNG NHẬN DIỆN NHÀ MẠNG (CARRIER / APN)
# ------------------------------------------------------------------------------
verify_sim_and_apn() {
    # 2.1 Kiểm tra SIM sẵn sàng qua AT port
    if [ -n "$AT_PORT" ] && [ -c "$AT_PORT" ]; then
        cpin=$(send_at "$AT_PORT" "AT+CPIN?")
        if echo "$cpin" | grep -qi "READY"; then
            log "SIM status: READY (Đã nhận diện thẻ SIM)."
        elif echo "$cpin" | grep -qi "SIM PIN"; then
            log "CẢNH BÁO: Thẻ SIM đang bị khóa mã PIN."
            return 1
        elif echo "$cpin" | grep -qiE "SIM NOT INSERTED|ERROR"; then
            log "CẢNH BÁO: Chưa cắm thẻ SIM hoặc tiếp xúc SIM chưa tốt."
            return 1
        fi

        # Đọc mã định danh SIM ICCID
        iccid=""
        for cmd in "AT+ICCID" "AT+CCID" "AT+QCCID"; do
            iccid=$(send_at "$AT_PORT" "$cmd" | grep -oE '[0-9]{18,20}' | head -n 1)
            [ -n "$iccid" ] && break
        done

        # Tự động gán APN chuẩn xác theo đầu số ICCID nhà mạng Việt Nam & Quốc tế
        case "$iccid" in
            898404*) APN="v-internet" ; log "Nhà mạng: Viettel Telecom (APN: v-internet)" ;;
            898401*) APN="m3-world"   ; log "Nhà mạng: VNPT Vinaphone (APN: m3-world)" ;;
            898402*) APN="m-i090"     ; log "Nhà mạng: MobiFone (APN: m-i090)" ;;
            898405*) APN="v-internet" ; log "Nhà mạng: Vietnamobile (APN: v-internet)" ;;
            898407*) APN="m3-world"   ; log "Nhà mạng: Wintel (APN: m3-world)" ;;
            898408*) APN="v-internet" ; log "Nhà mạng: FPT Telecom (APN: v-internet)" ;;
            *) 
                log "ICCID $iccid (Sử dụng APN mặc định: $APN)" 
                ;;
        esac
    elif [ "$PROTO" = "mbim" ] && [ -c "$CTRL_DEV" ] && command -v umbim >/dev/null 2>&1; then
        sub=$(umbim -n -d "$CTRL_DEV" subscriber 2>/dev/null)
        if echo "$sub" | grep -qiE 'ready|subscriber|ready_state: 1'; then
            log "SIM MBIM ready."
        fi
    fi

    # Ưu tiên nếu người dùng đã đặt APN tùy chỉnh trong UCI
    user_apn=$(uci -q get network.$IFACE.apn)
    [ -n "$user_apn" ] && APN="$user_apn"
    return 0
}

# ------------------------------------------------------------------------------
# BƯỚC 3: THI KẾT NỐI QUAY SỐ (DIALING EXECUTION)
# ------------------------------------------------------------------------------
dial_connection() {
    log "Tiến hành quay số cho $MODEM_NAME (Giao thức: $PROTO, APN: $APN)..."

    # Trường hợp 1: Qualcomm NSS MHI Acceleration (rmnet_mhi0 -> quectel-CM-M -> rmnet_mhi0.1)
    if [ "$PROTO" = "pcie_nss" ]; then
        DIALER=""
        for d in quectel-CM-M quectel-CM quectel-cm; do
            if command -v "$d" >/dev/null 2>&1; then
                DIALER="$d"
                break
            fi
        done

        if [ -n "$DIALER" ]; then
            if ! pgrep -f "$DIALER.*$APN" >/dev/null 2>&1 && ! pgrep -f "quectel-CM" >/dev/null 2>&1; then
                log "Khởi chạy daemon quay số $DIALER trên PCIe NSS MHI..."
                $DIALER -4 -6 -s "$APN" -f /tmp/quectel-cm.log &
                sleep 2
            fi
        fi

        # Cấu hình UCI DHCP trên card mạng ảo rmnet_mhi0.1
        uci -q batch <<EOF
set network.Modem=interface
set network.Modem.proto='dhcp'
set network.Modem.device='rmnet_mhi0.1'
set network.Modem.metric='10'
set network.Modem.peerdns='0'
add_list network.Modem.dns='8.8.8.8'
add_list network.Modem.dns='8.8.4.4'
set network.Modemv6=interface
set network.Modemv6.proto='dhcpv6'
set network.Modemv6.device='@Modem'
set network.Modemv6.extendprefix='1'
set network.Modemv6.metric='10'
set network.Modemv6.peerdns='0'
add_list network.Modemv6.dns='2001:4860:4860::8888'
add_list network.Modemv6.dns='2001:4860:4860::8844'
commit network
EOF

    # Trường hợp 2: Giao thức MBIM (PCIe MediaTek FM350-GL, Intel XMM, hoặc Upstream MHI)
    elif [ "$PROTO" = "mbim" ]; then
        uci -q batch <<EOF
set network.Modem=interface
set network.Modem.proto='mbim'
set network.Modem.device='$CTRL_DEV'
set network.Modem.apn='$APN'
set network.Modem.auth='none'
set network.Modem.pdptype='ipv4v6'
set network.Modem.metric='10'
set network.Modem.peerdns='0'
add_list network.Modem.dns='8.8.8.8'
add_list network.Modem.dns='8.8.4.4'
commit network
EOF

    # Trường hợp 3: Giao thức QMI (PCIe Upstream MHI QMI hoặc USB QMI)
    elif [ "$PROTO" = "qmi" ]; then
        uci -q batch <<EOF
set network.Modem=interface
set network.Modem.proto='qmi'
set network.Modem.device='$CTRL_DEV'
set network.Modem.apn='$APN'
set network.Modem.auth='none'
set network.Modem.pdptype='ipv4v6'
set network.Modem.metric='10'
commit network
EOF

    # Trường hợp 4: Giao thức XMM (Fibocom FM350-GL USB)
    elif [ "$PROTO" = "xmm" ]; then
        uci -q batch <<EOF
set network.Modem=interface
set network.Modem.proto='xmm'
set network.Modem.device='$CTRL_DEV'
set network.Modem.apn='$APN'
set network.Modem.auth='auto'
set network.Modem.pdp='ipv4v6'
set network.Modem.metric='10'
commit network
EOF

    # Trường hợp 5: USB Quectel Protocol
    elif [ "$PROTO" = "quectel" ]; then
        uci -q batch <<EOF
set network.Modem=interface
set network.Modem.proto='quectel'
set network.Modem.device='$CTRL_DEV'
set network.Modem.apn='$APN'
set network.Modem.auth='none'
set network.Modem.pdptype='ipv4v6'
set network.Modem.metric='10'
commit network
EOF

    # Trường hợp 6: USB DHCP / RNDIS / ECM
    elif [ "$PROTO" = "dhcp" ]; then
        uci -q batch <<EOF
set network.Modem=interface
set network.Modem.proto='dhcp'
set network.Modem.device='$NET_DEV'
set network.Modem.metric='10'
commit network
EOF
    fi

    # Cập nhật Firewall zone WAN
    zone_idx=0
    target_zone=""
    while true; do
        zname=$(uci -q get firewall.@zone[$zone_idx].name)
        [ -z "$zname" ] && break
        if [ "$zname" = "wan" ]; then
            target_zone="firewall.@zone[$zone_idx]"
            break
        fi
        zone_idx=$((zone_idx + 1))
    done
    [ -z "$target_zone" ] && target_zone="firewall.@zone[1]"

    uci -q add_list "$target_zone".network="Modem" 2>/dev/null
    uci -q add_list "$target_zone".network="Modemv6" 2>/dev/null
    uci -q add_list "$target_zone".network="wwan0" 2>/dev/null
    [ -n "$NET_DEV" ] && uci -q add_list "$target_zone".device="$NET_DEV" 2>/dev/null
    uci -q add_list "$target_zone".device="rmnet_mhi0.1" 2>/dev/null
    uci -q add_list "$target_zone".device="wwan0" 2>/dev/null
    uci commit firewall

    # Khởi động lại interface mạng
    if command -v ubus >/dev/null 2>&1; then
        ubus call network.interface.Modem up 2>/dev/null
        ubus call network.interface.Modemv6 up 2>/dev/null
    fi
    ifup Modem 2>/dev/null
    ifup Modemv6 2>/dev/null
    sleep 3
}

# ------------------------------------------------------------------------------
# BƯỚC 4: KIỂM CHỨNG KẾT NỐI VÀ VÒNG LẶP WATCHDOG TỰ ĐỘNG PHỤC HỒI
# ------------------------------------------------------------------------------
check_and_watchdog() {
    local fail_count=0
    while true; do
        if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
            if [ "$fail_count" -gt 0 ]; then
                log "✅ Kết nối Internet 5G/LTE đã phục hồi thành công!"
                fail_count=0
            fi
        else
            fail_count=$((fail_count + 1))
            log "⏳ Mất kết nối Internet (Lần $fail_count/3)..."
            if [ "$fail_count" -ge 3 ]; then
                log "⚠️ Đã mất kết nối liên tiếp 3 lần. Tiến hành tái khởi động quay số..."
                dial_connection
                fail_count=0
            fi
        fi

        # Nếu không chạy chế độ daemon, thoát ngay
        if [ "$1" != "--daemon" ]; then
            break
        fi
        sleep 25
    done
}

# ==============================================================================
# MAIN ENTRYPOINT
# ==============================================================================
discover_hardware || exit 0
verify_sim_and_apn || exit 1
dial_connection
check_and_watchdog "$1"
