#!/bin/sh
# ==============================================================================
# 🚀 DUYDOAN 5G/LTE CELLULAR PROTOCOL HANDLER FOR OPENWRT NETIFD
# Tác giả: DOANDUY
# ==============================================================================

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. ../netifd-proto.sh
	init_proto "$@"
}

proto_duydoan5g_init_config() {
	available=1
	no_device=1
	proto_config_add_string "apn"
	proto_config_add_string "pincode"
	proto_config_add_string "pdp"
	proto_config_add_string "metric"
	proto_config_add_defaults
}

proto_duydoan5g_setup() {
	local interface="$1"
	local apn pincode pdp metric

	json_get_vars apn pincode pdp metric
	[ -z "$apn" ] && apn="v-internet"
	[ -z "$metric" ] && metric="10"

	logger -t "duydoan5g" "Starting DuyDoan 5G Cellular setup for interface $interface (APN=$apn)..."

	# 1. Phát hiện phần cứng PCIe hoặc USB
	local is_pcie_mhi=0
	local net_dev="rmnet_mhi0.1"
	local at_port="/dev/mhi_DUN"

	if [ -d "/sys/bus/pci/drivers/pcie_mhi" ] || [ -d "/sys/bus/pci/drivers/mhi_q" ] || [ -d "/sys/class/net/rmnet_mhi0" ] || [ -c "/dev/mhi_DUN" ]; then
		is_pcie_mhi=1
		net_dev="rmnet_mhi0.1"
		at_port="/dev/mhi_DUN"
	elif [ -d "/sys/bus/pci/drivers/mtk_t7xx" ] || [ -c "/dev/wwan0mbim0" ]; then
		net_dev="wwan0"
		at_port="/dev/wwan0at0"
	elif [ -c "/dev/cdc-wdm0" ]; then
		net_dev="wwan0"
		at_port="/dev/ttyUSB2"
	fi

	# 2. Tự động kiểm tra SIM & ICCID nếu chưa cấu hình APN cụ thể
	if [ -c "$at_port" ] && command -v sms_tool >/dev/null 2>&1; then
		local iccid=$(sms_tool -D -d "$at_port" at "AT+ICCID" 2>/dev/null | grep -oE '[0-9]{18,20}' | head -n 1)
		[ -z "$iccid" ] && iccid=$(sms_tool -D -d "$at_port" at "AT+CCID" 2>/dev/null | grep -oE '[0-9]{18,20}' | head -n 1)
		if [ -n "$iccid" ] && [ "$apn" = "v-internet" ]; then
			case "$iccid" in
				898404*) apn="v-internet" ;;
				898401*) apn="m3-world" ;;
				898402*) apn="m-i090" ;;
				898407*) apn="m3-world" ;;
				898408*) apn="v-internet" ;;
			esac
		fi
	fi

	# 3. Khởi chạy tiến trình quay số phần cứng
	if [ "$is_pcie_mhi" -eq 1 ]; then
		local dialer="quectel-CM-M"
		command -v "$dialer" >/dev/null 2>&1 || dialer="quectel-CM"

		if ! pgrep -f "$dialer.*$apn" >/dev/null 2>&1 && ! pgrep -f "quectel-CM" >/dev/null 2>&1; then
			killall -9 "$dialer" 2>/dev/null
			sleep 1
			$dialer -4 -6 -s "$apn" -f /tmp/quectel-cm.log &
			sleep 3
		fi
	fi

	# 4. Chờ thiết bị mạng sẵn sàng và có IP (Tối đa 15s)
	local waited=0
	local ip4=""
	while [ "$waited" -lt 15 ]; do
		ip4=$(ip -4 addr show dev "$net_dev" 2>/dev/null | grep -oE 'inet [0-9.]+' | cut -d' ' -f2)
		[ -n "$ip4" ] && break
		sleep 1
		waited=$((waited + 1))
	done

	if [ -z "$ip4" ]; then
		logger -t "duydoan5g" "Chưa nhận được IP trên $net_dev, chạy udhcpc..."
		udhcpc -f -q -n -t 3 -i "$net_dev"
		ip4=$(ip -4 addr show dev "$net_dev" 2>/dev/null | grep -oE 'inet [0-9.]+' | cut -d' ' -f2)
	fi

	if [ -z "$ip4" ]; then
		logger -t "duydoan5g" "Lỗi: Không nhận được IP từ trạm BTS!"
		proto_notify_error "$interface" NO_ADDRESS
		proto_block_restart "$interface"
		return 1
	fi

	local gw=$(ip -4 route show dev "$net_dev" 2>/dev/null | grep default | awk '{print $3}' | head -n 1)
	[ -z "$gw" ] && gw=$(echo "$ip4" | awk -F. '{print $1"."$2"."$3"."($4==1?2:($4==201?202:1))}')

	logger -t "duydoan5g" "Kết nối 5G thành công: IP=$ip4, GW=$gw, NetDev=$net_dev"

	# 5. Đăng ký thông tin vào netifd
	proto_init_update "$net_dev" 1
	proto_add_ipv4_address "$ip4" "30"
	proto_add_ipv4_route "0.0.0.0" "0" "$gw" "$ip4" "$metric"
	proto_add_dns_server "8.8.8.8"
	proto_add_dns_server "8.8.4.4"

	local ip6=$(ip -6 addr show dev "$net_dev" 2>/dev/null | grep -oE 'inet6 [0-9a-f:]+/64' | cut -d' ' -f2 | grep -v '^fe80' | head -n 1)
	if [ -n "$ip6" ]; then
		proto_add_ipv6_address "${ip6%/*}" "64"
		proto_add_dns_server "2001:4860:4860::8888"
		proto_add_dns_server "2001:4860:4860::8844"
	fi

	proto_send_update "$interface"
}

proto_duydoan5g_teardown() {
	local interface="$1"
	logger -t "duydoan5g" "Tearing down DuyDoan 5G Cellular interface $interface..."
	killall -9 quectel-CM-M quectel-CM 2>/dev/null
	proto_init_update "*" 0
	proto_send_update "$interface"
}

add_protocol duydoan5g
