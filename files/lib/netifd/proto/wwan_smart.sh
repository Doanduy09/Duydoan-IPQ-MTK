#!/bin/sh
# ==============================================================================
# 🚀 UNIVERSAL WWAN & TETHERING NETIFD PROTOCOL HANDLER (OPENWRT / IMMORTALWRT)
# Thống nhất 1 PROTOCOL duy nhất: 'wwan_smart' (hoặc 'wwan')
# Tương thích 100% mọi Card WWAN 4G/5G (PCIe & USB) và Mọi Smartphone (Android & iOS)
# Tích hợp cơ chế tự động giật lại IP khi bị nhà mạng thu hồi sau 24h
# ==============================================================================

. /lib/functions.sh
. ../netifd-proto.sh
init_proto "$@"

proto_wwan_smart_init_config() {
	available=1
	no_device=1

	proto_config_add_string "apn"
	proto_config_add_string "device"
	proto_config_add_string "delay"
	proto_config_add_string "metric"
	proto_config_add_string "ip6table"
}

proto_wwan_smart_setup() {
	local interface="$1"
	local apn device delay metric

	json_get_vars apn device delay metric
	[ -n "$delay" ] && sleep "$delay"

	# 1. Gọi Master Dialer tự hành quét & quay số
	if [ -x "/usr/bin/wwan_smart_dialer.sh" ]; then
		/usr/bin/wwan_smart_dialer.sh dial "${apn:-auto}" >/dev/null 2>&1
	fi

	# 2. Lấy cổng mạng dữ liệu đã được nhận diện
	local netdev=""
	if [ -s "/tmp/wwan_state/netdev" ]; then
		netdev=$(cat /tmp/wwan_state/netdev 2>/dev/null | tr -d ' \r\n')
	fi
	[ -z "$netdev" ] && netdev="${device:-eth2}"

	# 3. Kiểm tra xem interface vật lý có tồn tại không
	local retries=0
	while [ ! -d "/sys/class/net/$netdev" ] && [ "$retries" -lt 10 ]; do
		sleep 1
		retries=$((retries + 1))
	done

	[ -d "/sys/class/net/$netdev" ] || {
		echo "wwan_smart[$$] Không tìm thấy interface dữ liệu: $netdev"
		proto_notify_error "$interface" NO_DEVICE
		proto_block_restart "$interface"
		return 1
	}

	echo "wwan_smart[$$] Khởi tạo interface [$interface] liên kết với thiết bị mạng [$netdev]"

	# Đảm bảo thiết bị mạng bật UP
	ip link set "$netdev" up 2>/dev/null
	ip link set "$netdev" txqueuelen 2048 2>/dev/null

	# 4. Báo cáo trạng thái UP cho netifd
	proto_init_update "$netdev" 1
	proto_send_update "$interface"

	# 5. Khởi chạy udhcpc quản lý qua netifd
	proto_run_command "$interface" udhcpc \
		-p /var/run/udhcpc-$interface.pid \
		-s /lib/netifd/dhcpc.script \
		-f -t 0 -i "$netdev" \
		-C -O 121 -O 33 -O 249 \
		${metric:+-m $metric}

	# 6. Khởi chạy odhcp6c cho IPv6 Native nếu có
	if command -v odhcp6c >/dev/null 2>&1; then
		proto_run_command "$interface" odhcp6c \
			-s /lib/netifd/dhcpv6.script \
			-P0 \
			${metric:+-m $metric} \
			"$netdev"
	fi

	# 7. Khởi chạy Watchdog tự động giật lại IP khi nhà mạng thu hồi sau 24h
	if [ -x "/lib/netifd/wwan_carrier_watchdog.sh" ]; then
		proto_run_command "$interface" /lib/netifd/wwan_carrier_watchdog.sh "$interface" "$netdev"
	fi
}

proto_wwan_smart_teardown() {
	local interface="$1"
	echo "wwan_smart[$$] Dừng kết nối interface [$interface]"
	proto_kill_command "$interface"
}

# Đăng ký cả 'wwan_smart' và 'wwan' để thống nhất 1 proto cho toàn bộ hệ thống
add_protocol wwan_smart
add_protocol wwan
