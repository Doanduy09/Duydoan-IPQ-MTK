#!/bin/sh
# ==============================================================================
# 🚀 DUYDOAN 5G/LTE CELLULAR PROTOCOL HANDLER FOR OPENWRT NETIFD
# Tác giả: DOANDUY
# ==============================================================================

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	[ -f /lib/netifd/netifd-proto.sh ] && . /lib/netifd/netifd-proto.sh || . ../netifd-proto.sh
	init_proto "$@"
}

proto_duydoan5g_init_config() {
	available=1
	no_device=1
	proto_config_add_string "apn"
	proto_config_add_string "pincode"
	proto_config_add_string "pdp"
	proto_config_add_string "metric"
	proto_config_add_int "delay"
	proto_config_add_defaults
}

proto_duydoan5g_setup() {
	local interface="$1"
	local apn pincode pdp metric delay

	json_get_vars apn pincode pdp metric delay
	[ -z "$apn" ] && apn="v-internet"
	[ -z "$metric" ] && metric="10"
	[ -n "$delay" ] && sleep "$delay"

	logger -t "duydoan5g" "Starting DuyDoan 5G setup for $interface (APN=$apn)..."

	# 1. Kiem tra PCIe SBL mode (0x010c) & Khoa Power Management ON
	if [ -d "/sys/bus/pci/devices/0000:01:00.0" ]; then
		echo on > /sys/bus/pci/devices/0000:01:00.0/power/control 2>/dev/null
		local pci_subsys=$(cat /sys/bus/pci/devices/0000:01:00.0/subsystem_device 2>/dev/null)
		if [ "$pci_subsys" = "0x010c" ]; then
			logger -t "duydoan5g" "Rescanning PCIe bus for Sierra modem..."
			echo 1 > /sys/bus/pci/devices/0000:01:00.0/remove 2>/dev/null
			sleep 1
			echo 1 > /sys/bus/pci/rescan 2>/dev/null
			sleep 2
			echo on > /sys/bus/pci/devices/0000:01:00.0/power/control 2>/dev/null
		fi
	fi

	# 2. Nhan dien phan cung
	local ifname="mhi_hwip0"
	local at_port="/dev/wwan0at0"
	local cm_extra="-n 1 -m 1 -4"

	if [ -d "/sys/class/net/rmnet_mhi0" ] || [ -c "/dev/mhi_DUN" ]; then
		ifname="rmnet_mhi0.1"
		at_port="/dev/mhi_DUN"
		cm_extra="-4 -6"
	elif [ -d "/sys/class/net/mhi_hwip0" ] || [ -c "/dev/wwan0qmi0" ]; then
		ifname="mhi_hwip0"
		at_port="/dev/wwan0at0"
		cm_extra="-n 1 -m 1 -4"
	elif [ -d "/sys/class/net/wwan0" ]; then
		ifname="wwan0"
		at_port="/dev/wwan0at0"
		cm_extra="-4 -6"
	elif [ -c "/dev/cdc-wdm0" ]; then
		ifname="wwan0"
		at_port="/dev/ttyUSB2"
		cm_extra="-4 -6"
	fi

	echo "$interface" > /tmp/wd_interface
	echo "$ifname" > /tmp/wd_device
	echo "$at_port" > /tmp/master_sms_port

	# 3. Tu dong kiem tra SIM ICCID
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

	# 4. Khoi chay quay so thong qua proto_run_command
	local dialer="/usr/bin/quectel-CM-M"
	[ -x "$dialer" ] || dialer="/usr/bin/quectel-CM"

	killall -9 quectel-CM-M quectel-CM 2>/dev/null
	sleep 1

	proto_run_command "$interface" "$dialer" -i "$ifname" -s "$apn" $cm_extra -f /tmp/quectel-cm.log
	sleep 4

	# 5. Cho co IP tu nha mang (Toi da 20s)
	local waited=0
	local ip4=""
	while [ "$waited" -lt 20 ]; do
		ip4=$(ip -4 addr show dev "$ifname" 2>/dev/null | grep -oE 'inet [0-9.]+' | cut -d' ' -f2 | head -n 1)
		[ -n "$ip4" ] && break
		sleep 1
		waited=$((waited + 1))
	done

	if [ -z "$ip4" ]; then
		logger -t "duydoan5g" "udhcpc on $ifname..."
		udhcpc -f -q -n -t 3 -i "$ifname"
		ip4=$(ip -4 addr show dev "$ifname" 2>/dev/null | grep -oE 'inet [0-9.]+' | cut -d' ' -f2 | head -n 1)
	fi

	if [ -z "$ip4" ]; then
		logger -t "duydoan5g" "Loi: Khong nhan duoc IP!"
		proto_notify_error "$interface" NO_ADDRESS
		proto_block_restart "$interface"
		return 1
	fi

	local gw=$(ip -4 route show dev "$ifname" 2>/dev/null | grep default | awk '{print $3}' | head -n 1)
	[ -z "$gw" ] && gw=$(echo "$ip4" | awk -F. '{print $1"."$2"."$3"."($4==1?2:($4==201?202:1))}')

	logger -t "duydoan5g" "Ket noi 5G thanh cong: IP=$ip4, GW=$gw, NetDev=$ifname"

	# 6. Dang ky voi netifd
	proto_init_update "$ifname" 1
	proto_set_keep 1
	proto_add_data
	json_add_string "zone" "wan"
	proto_close_data
	proto_add_ipv4_address "$ip4" "30"
	proto_add_ipv4_route "0.0.0.0" "0" "$gw" "$ip4" "$metric"
	proto_add_dns_server "8.8.8.8"
	proto_add_dns_server "8.8.4.4"
	proto_add_dns_server "116.98.212.54"
	proto_add_dns_server "203.113.131.5"

	local ip6=$(ip -6 addr show dev "$ifname" 2>/dev/null | grep -oE 'inet6 [0-9a-f:]+/64' | cut -d' ' -f2 | grep -v '^fe80' | head -n 1)
	if [ -n "$ip6" ]; then
		proto_add_ipv6_address "${ip6%/*}" "64"
		proto_add_dns_server "2001:4860:4860::8888"
		proto_add_dns_server "2001:4860:4860::8844"
	fi

	proto_send_update "$interface"

	# Tu dong gan interface vao Firewall WAN zone neu chua co
	if command -v uci >/dev/null 2>&1; then
		if ! uci -q get firewall.@zone[1].network | grep -qw "$interface"; then
			uci -q add_list firewall.@zone[1].network="$interface"
			uci -q commit firewall
			/etc/init.d/firewall reload >/dev/null 2>&1 &
		fi
	fi
}

proto_duydoan5g_teardown() {
	local interface="$1"
	logger -t "duydoan5g" "Tearing down DuyDoan 5G interface $interface..."
	proto_kill_command "$interface"
	killall -9 quectel-CM-M quectel-CM 2>/dev/null
	proto_init_update "*" 0
	proto_send_update "$interface"
}

add_protocol duydoan5g
