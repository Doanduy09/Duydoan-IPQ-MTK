#!/bin/sh
# ==============================================================================
# 🚀 TỰ ĐỘNG QUAY SỐ MODEM 5G/LTE KHI ĐỦ ĐIỀU KIỆN (AUTO-DIAL ENGINE)
# Hỗ trợ: Fibocom FM350-GL / MTK T700 (PCIe MBIM), Qualcomm MHI, Quectel/Sierra/SIMCOM USB
# Tác giả: DOANDUY - Swaiot S10-SKY (IPQ8071/IPQ8074)
# ==============================================================================

IFACE="wwan0"
PROTO="mbim"
DEV=""
PORT=""

# 1. Nhận diện phần cứng modem
if [ -c "/dev/wwan0mbim0" ] || [ -c "/dev/wwan0at0" ] || [ -d "/sys/bus/pci/drivers/mtk_t7xx" ]; then
    DEV="/dev/wwan0mbim0"
    PORT="/dev/wwan0at0"
    PROTO="mbim"
    IFACE="wwan0"
    echo "Fibocom FM350-GL 5G (PCIe MTK T700)" > /tmp/master_m_type
elif [ -c "/dev/mhi_DUN" ] || [ -d "/sys/bus/mhi" ]; then
    PORT="/dev/mhi_DUN"
    if [ -c "/dev/mhi_MBIM" ]; then
        DEV="/dev/mhi_MBIM"
        PROTO="mbim"
    else
        DEV="/dev/mhi_QMI0"
        PROTO="qmi"
    fi
    IFACE="wwan0"
    echo "Qualcomm Snapdragon 5G (PCIe MHI)" > /tmp/master_m_type
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
if [ -c "$PORT" ] && command -v atinout >/dev/null 2>&1; then
    cpin_res=$(echo "AT+CPIN?" | timeout 3 atinout - "$PORT" - 2>/dev/null)
    if echo "$cpin_res" | grep -qi "READY"; then
        SIM_READY=1
    fi
elif [ "$PROTO" = "mbim" ] && [ -c "$DEV" ] && command -v umbim >/dev/null 2>&1; then
    # Kiểm tra qua MBIM
    mbim_sub=$(umbim -n -d "$DEV" subscriber 2>/dev/null)
    if echo "$mbim_sub" | grep -qiE 'ready|subscriber|ready_state: 1'; then
        SIM_READY=1
    fi
else
    # Mặc định thử quay số
    SIM_READY=1
fi

if [ "$SIM_READY" -ne 1 ]; then
    echo "[AUTODIAL] SIM chưa sẵn sàng hoặc bị khóa PIN (cần kiểm tra lại SIM)."
    exit 1
fi

# 3. Tự động xác định APN nhà mạng chuẩn xác
APN="v-internet"
if [ -c "$PORT" ] && command -v atinout >/dev/null 2>&1; then
    iccid=$(echo "AT+ICCID" | timeout 2 atinout - "$PORT" - 2>/dev/null | grep -oE '[0-9]{18,20}')
    [ -z "$iccid" ] && iccid=$(echo "AT+CCID" | timeout 2 atinout - "$PORT" - 2>/dev/null | grep -oE '[0-9]{18,20}')
    [ -z "$iccid" ] && iccid=$(echo "AT+QCCID" | timeout 2 atinout - "$PORT" - 2>/dev/null | grep -oE '[0-9]{18,20}')
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

# 4. Đồng bộ vào UCI cấu hình nếu chưa khớp
cur_proto=$(uci -q get network.$IFACE.proto)
cur_dev=$(uci -q get network.$IFACE.device)

if [ "$cur_proto" != "$PROTO" ] || [ "$cur_dev" != "$DEV" ]; then
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
    uci -q add_list "$target_zone".device="wwan0" 2>/dev/null
    uci commit firewall
fi

# 5. Kích hoạt quay số
if command -v ubus >/dev/null 2>&1; then
    ubus call network.interface.$IFACE up 2>/dev/null
fi
ifup "$IFACE" 2>/dev/null
sleep 3

# Kiểm tra kết nối Internet
if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo "[AUTODIAL] ✅ Kết nối Internet qua 5G/LTE thành công!"
else
    echo "[AUTODIAL] ⏳ Đang kết nối trạm BTS và chờ cấp IP..."
fi
