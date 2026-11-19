#!/bin/sh
# ==============================================================================
# 🛡️ NETIFD CARRIER 24H IP REVOCATION WATCHDOG (TỰ GIẬT LẠI IP KHI BỊ THU HỒI)
# Tự động giám sát địa chỉ IP, phản xạ trong 15s khi nhà mạng ngắt phiên 24h
# Cấp 1: Renew DHCP -> Cấp 2: Re-attach PDP Context -> Cấp 3: Netifd Auto-Replay
# Hoàn toàn không làm ngắt LAN/Wi-Fi, 0s Downtime đối với người dùng
# ==============================================================================

INTERFACE="$1"
NETDEV="$2"

[ -z "$INTERFACE" ] && INTERFACE="wwan"
[ -z "$NETDEV" ] && NETDEV=$(cat /tmp/wwan_state/netdev 2>/dev/null || echo "eth2")

FAIL_STREAK=0

logger -t "wwan_watchdog[$$]" "Khởi động giám sát 24h IP thu hồi cho interface [$INTERFACE] trên card [$NETDEV]"

while true; do
    sleep 15

    # 1. Nếu interface vật lý bị rút / mất, thoát an toàn
    [ -d "/sys/class/net/$NETDEV" ] || exit 0

    # 2. Kiểm tra IP thực tế trên interface
    HAS_IP=0
    if ip -4 addr show dev "$NETDEV" 2>/dev/null | grep -q "inet "; then
        HAS_IP=1
    fi

    # 3. Kiểm tra thông mạng qua Anycast Ping (1.1.1.1 / 8.8.8.8)
    PING_OK=0
    if [ "$HAS_IP" -eq 1 ]; then
        if ping -I "$NETDEV" -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -I "$NETDEV" -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            PING_OK=1
        fi
    fi

    if [ "$PING_OK" -eq 1 ]; then
        FAIL_STREAK=0
        continue
    fi

    FAIL_STREAK=$((FAIL_STREAK + 1))
    logger -t "wwan_watchdog[$$]" "Cảnh báo: Interface [$INTERFACE/$NETDEV] mất kết nối hoặc bị nhà mạng thu hồi IP (Lần $FAIL_STREAK/3)!"

    # CẤP 1: Gửi tín hiệu Renew DHCP nhanh (Yêu cầu IP mới từ trạm phát)
    if [ "$FAIL_STREAK" -eq 1 ]; then
        logger -t "wwan_watchdog[$$]" ">> [Cấp 1] Gửi tín hiệu Renew DHCP..."
        PID_FILE="/var/run/udhcpc-$INTERFACE.pid"
        if [ -s "$PID_FILE" ]; then
            kill -SIGUSR2 $(cat "$PID_FILE") 2>/dev/null || kill -SIGUSR1 $(cat "$PID_FILE") 2>/dev/null
        else
            udhcpc -i "$NETDEV" -n -q -R 2>/dev/null &
        fi
        continue
    fi

    # CẤP 2: Tái gắn kết PDP Context qua lệnh AT
    if [ "$FAIL_STREAK" -eq 2 ]; then
        logger -t "wwan_watchdog[$$]" ">> [Cấp 2] Tái kích hoạt PDP Context qua wwan_smart_dialer.sh heal..."
        if [ -x /usr/bin/wwan_smart_dialer.sh ]; then
            /usr/bin/wwan_smart_dialer.sh heal >/dev/null 2>&1
        fi
        continue
    fi

    # CẤP 3: Nhà mạng đã hủy phiên dữ liệu 24h! Kích hoạt Netifd tái khởi tạo toàn diện
    if [ "$FAIL_STREAK" -ge 3 ]; then
        logger -t "wwan_watchdog[$$]" ">> [Cấp 3] Xác nhận nhà mạng thu hồi IP 24h! Tái tạo phiên di động qua ubus netifd..."
        if command -v ubus >/dev/null 2>&1; then
            ubus call network.interface."$INTERFACE" down 2>/dev/null
            sleep 2
            ubus call network.interface."$INTERFACE" up 2>/dev/null
        else
            ifdown "$INTERFACE" 2>/dev/null
            sleep 2
            ifup "$INTERFACE" 2>/dev/null
        fi
        FAIL_STREAK=0
        sleep 10
    fi
done
