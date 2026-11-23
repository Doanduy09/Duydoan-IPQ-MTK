#!/bin/sh
# ==============================================================================
# 🚀 TỰ ĐỘNG QUAY SỐ MODEM 5G/LTE KHI ĐỦ ĐIỀU KIỆN (AUTO-DIAL ENGINE)
# Hỗ trợ: 
#   - Qualcomm Snapdragon 5G PCIe (pcie_mhi + rmnet_nss, Sierra EM9190/Quectel SDX55)
#   - Fibocom FM350-GL USB (xmm) & PCIe (mbim / MTK T700)
#   - Quectel / Sierra / SIMCOM USB (qmi, mbim, quectel)
# Tác giả: DOANDUY
# ==============================================================================

IFACE="wwan0"
PROTO="mbim"
DEV=""
PORT=""
IS_PCIE_MHI=0

# Helper gửi lệnh AT đa năng
send_at() {
    local p="$1"
    local cmd="$2"
    [ ! -c "$p" ] && return 1
    if command -v sms_tool >/dev/null 2>&1; then
        sms_tool -D -d "$p" at "$cmd" 2>/dev/null
    elif command -v atinout >/dev/null 2>&1; then
        echo "$cmd" | timeout 3 atinout - "$p" - 2>/dev/null
    elif command -v gcom >/dev/null 2>&1; then
        printf 'send "%s\\r"\nwait 1 "OK"\n' "$cmd" | timeout 3 gcom -d "$p" -s /dev/stdin 2>/dev/null
    fi
}

# 1. Nhận diện phần cứng modem
if [ -d "/sys/bus/pci/drivers/pcie_mhi" ] || [ -d "/sys/class/net/rmnet_mhi0" ] || [ -c "/dev/mhi_DUN" ] || [ -c "/dev/mhi_0306_00.01.00_d.mhi_at0" ]; then
    IS_PCIE_MHI=1
    IFACE="Modem"
    DEV="rmnet_mhi0.1"
    PROTO="dhcp"
    PORT="/dev/mhi_DUN"
    [ ! -c "$PORT" ] && [ -c "/dev/mhi_0306_00.01.00_d.mhi_at0" ] && PORT="/dev/mhi_0306_00.01.00_d.mhi_at0"
    [ ! -c "$PORT" ] && [ -c "/dev/mhi_at0" ] && PORT="/dev/mhi_at0"
    echo "Qualcomm Snapdragon 5G (PCIe pcie_mhi + rmnet_nss)" > /tmp/master_m_type
elif [ -c "/dev/wwan0mbim0" ] || [ -c "/dev/wwan0at0" ] || [ -d "/sys/bus/pci/drivers/mtk_t7xx" ]; then
    DEV="/dev/wwan0mbim0"
    PORT="/dev/wwan0at0"
    PROTO="mbim"
    IFACE="wwan0"
    echo "Fibocom FM350-GL 5G (PCIe MTK T700)" > /tmp/master_m_type
elif lsusb 2>/dev/null | grep -iqE "0e8d:7127|fm350" || [ -c "/dev/ttyUSB3" -a -f "/lib/netifd/proto/xmm.sh" ]; then
    DEV="/dev/ttyUSB3"
    PORT="/dev/ttyUSB1"
    PROTO="xmm"
    IFACE="wwan0"
    echo "Fibocom FM350-GL 5G (USB XMM)" > /tmp/master_m_type
elif [ -c "/dev/mhi_QMI0" ] || [ -d "/sys/bus/mhi" ]; then
    PORT="/dev/mhi_DUN"
    if [ -c "/dev/mhi_MBIM" ]; then
        DEV="/dev/mhi_MBIM"
        PROTO="mbim"
    else
        DEV="/dev/mhi_QMI0"
        PROTO="qmi"
    fi
    IFACE="wwan0"
    echo "Qualcomm Snapdragon 5G (PCIe MHI Generic)" > /tmp/master_m_type
elif [ -c "/dev/cdc-wdm0" ]; then
    DEV="/dev/cdc-wdm0"
    PORT="/dev/ttyUSB2"
    [ -c "/dev/ttyUSB0" ] && lsusb 2>/dev/null | grep -iqE "1199:|sierra" && PORT="/dev/ttyUSB0"
    PROTO="mbim"
    lsusb 2>/dev/null | grep -iqE "2c7c:|quectel" && PROTO="quectel"
    IFACE="wwan0"
elif [ -d "/sys/class/net/usb0" ]; then
    DEV="usb0"
    PORT="/dev/ttyUSB2"
    PROTO="dhcp"
    IFACE="usb0"
else
    echo "[AUTODIAL] Chưa phát hiện card modem nào."
    exit 0
fi

[ -n "$PORT" ] && echo "$PORT" > /tmp/master_sms_port
[ -n "$PORT" ] && echo "$PORT" > /tmp/custom_at_port

# 2. Kiểm tra điều kiện SIM sẵn sàng
SIM_READY=0
if [ -c "$PORT" ]; then
    cpin_res=$(send_at "$PORT" "AT+CPIN?")
    if echo "$cpin_res" | grep -qi "READY"; then
        SIM_READY=1
    fi
elif [ "$PROTO" = "mbim" ] && [ -c "$DEV" ] && command -v umbim >/dev/null 2>&1; then
    mbim_sub=$(umbim -n -d "$DEV" subscriber 2>/dev/null)
    if echo "$mbim_sub" | grep -qiE 'ready|subscriber|ready_state: 1'; then
        SIM_READY=1
    fi
else
    SIM_READY=1
fi

if [ "$SIM_READY" -ne 1 ]; then
    echo "[AUTODIAL] SIM chưa sẵn sàng hoặc bị khóa PIN (cần kiểm tra lại SIM)."
    exit 1
fi

# 3. Tự động xác định APN nhà mạng chuẩn xác
APN="v-internet"
if [ -c "$PORT" ]; then
    iccid=$(send_at "$PORT" "AT+ICCID" | grep -oE '[0-9]{18,20}')
    [ -z "$iccid" ] && iccid=$(send_at "$PORT" "AT+CCID" | grep -oE '[0-9]{18,20}')
    [ -z "$iccid" ] && iccid=$(send_at "$PORT" "AT+QCCID" | grep -oE '[0-9]{18,20}')
    case "$iccid" in
        898404*) APN="v-internet" ;; # Viettel
        898401*) APN="m3-world" ;;   # Vinaphone
        898402*) APN="m-i090" ;;     # Mobifone
        898405*) APN="v-internet" ;; # Vietnamobile
        898407*) APN="m3-world" ;;   # Wintel
        *) APN="v-internet" ;;
    esac
fi

saved_apn=$(uci -q get network.$IFACE.apn)
[ -n "$saved_apn" ] && APN="$saved_apn"

echo "[AUTODIAL] Modem sẵn sàng! Cấu hình $IFACE ($PROTO, dev=$DEV, APN=$APN)..."

# 4. Khởi chạy tiến trình quay số phần cứng nếu là PCIe MHI
if [ "$IS_PCIE_MHI" -eq 1 ]; then
    DIALER=""
    for d in quectel-CM-M quectel-CM quectel-cm; do
        if command -v "$d" >/dev/null 2>&1; then
            DIALER="$d"
            break
        fi
    done
    if [ -n "$DIALER" ]; then
        if ! pgrep -f "$DIALER.*$APN" >/dev/null 2>&1 && ! pgrep -f "quectel-CM" >/dev/null 2>&1; then
            echo "[AUTODIAL] Khởi động $DIALER trên PCIe NSS rmnet_mhi0..."
            $DIALER -4 -6 -s "$APN" -f /tmp/quectel-cm.log &
            sleep 2
        fi
    fi
fi

# 5. Đồng bộ vào UCI cấu hình nếu chưa khớp
cur_proto=$(uci -q get network.$IFACE.proto)
cur_dev=$(uci -q get network.$IFACE.device)

if [ "$cur_proto" != "$PROTO" ] || [ "$cur_dev" != "$DEV" ]; then
    if [ "$IS_PCIE_MHI" -eq 1 ]; then
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
    elif [ "$PROTO" = "xmm" ]; then
        uci -q batch <<EOF
set network.$IFACE=interface
set network.$IFACE.proto='xmm'
set network.$IFACE.device='$DEV'
set network.$IFACE.apn='$APN'
set network.$IFACE.auth='auto'
set network.$IFACE.pdp='ipv4v6'
set network.$IFACE.metric='1'
commit network
EOF
    else
        uci -q batch <<EOF
set network.$IFACE=interface
set network.$IFACE.proto='$PROTO'
set network.$IFACE.device='$DEV'
set network.$IFACE.apn='$APN'
set network.$IFACE.auth='none'
set network.$IFACE.pdptype='ipv4v6'
set network.$IFACE.metric='10'
commit network
EOF
    fi

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
    uci -q add_list "$target_zone".network="$IFACE" 2>/dev/null
    [ "$IS_PCIE_MHI" -eq 1 ] && uci -q add_list "$target_zone".network="Modemv6" 2>/dev/null
    [ "$IS_PCIE_MHI" -eq 1 ] && uci -q add_list "$target_zone".device="rmnet_mhi0.1" 2>/dev/null
    uci -q add_list "$target_zone".device="wwan0" 2>/dev/null
    uci -q add_list "$target_zone".device="eth2" 2>/dev/null
    uci commit firewall
fi

# 6. Kích hoạt quay số / DHCP
if command -v ubus >/dev/null 2>&1; then
    ubus call network.interface.$IFACE up 2>/dev/null
    [ "$IS_PCIE_MHI" -eq 1 ] && ubus call network.interface.Modemv6 up 2>/dev/null
fi
ifup "$IFACE" 2>/dev/null
[ "$IS_PCIE_MHI" -eq 1 ] && ifup "Modemv6" 2>/dev/null
sleep 3

# 7. Kiểm tra kết nối Internet
if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo "[AUTODIAL] ✅ Kết nối Internet qua 5G/LTE thành công!"
else
    echo "[AUTODIAL] ⏳ Đang kết nối trạm BTS và chờ cấp IP..."
fi
