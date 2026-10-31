#!/bin/sh

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. ../netifd-proto.sh
	init_proto "$@"
}
#DBG=-v

proto_mbim_init_config() {
	available=1
	no_device=1
	proto_config_add_string "device:device"
	proto_config_add_string apn
	proto_config_add_string pincode
	proto_config_add_string delay
	proto_config_add_boolean allow_roaming
	proto_config_add_boolean allow_partner
	proto_config_add_string auth
	proto_config_add_string username
	proto_config_add_string password
	[ -e /proc/sys/net/ipv6 ] && proto_config_add_string ipv6
	proto_config_add_string devpath
	proto_config_add_string dhcp
	proto_config_add_string dhcpv6
	proto_config_add_boolean sourcefilter
	proto_config_add_boolean delegate
	proto_config_add_string pdptype
	proto_config_add_int mtu
	proto_config_add_defaults
}

_proto_mbim_get_field() {
        local field="$1"
        shift
        local mbimconfig="$@"
        echo "$mbimconfig" | while read -r line; do
                variable=${line%%:*}
                [ "$variable" = "$field" ] || continue;
                value=${line##* }
                echo -n "$value "
        done
}

_proto_mbim_setup() {
	local interface="$1"
	local tid=2
	local ret

	local allow_partner allow_roaming apn auth delay device devpath password pincode username
	json_get_vars allow_partner allow_roaming apn auth delay device devpath password pincode username

	local dhcp dhcpv6 pdptype
	json_get_vars dhcp dhcpv6 pdptype

	local delegate ip4table ip6table mtu sourcefilter $PROTO_DEFAULT_OPTIONS
	json_get_vars delegate ip4table ip6table mtu sourcefilter $PROTO_DEFAULT_OPTIONS

	[ ! -e /proc/sys/net/ipv6 ] && ipv6=0 || json_get_var ipv6 ipv6

	[ -n "$ctl_device" ] && device=$ctl_device

	if [ -n "$devpath" ]; then
		local usbmisc_or_wwan_path
		for usbmisc_or_wwan_path in \
		    "$devpath"/usbmisc/cdc-wdm* \
		    "$devpath"/*/usbmisc/cdc-wdm* \
		    "$devpath"/*/wwan[0-9]*/wwan[0-9]*mbim* \
		    "$devpath"/*/*/wwan[0-9]*/wwan[0-9]*mbim*; do
			[ ! -e "$usbmisc_or_wwan_path" ] && continue
			device="/dev/${usbmisc_or_wwan_path##*/}"
			break
		done
	fi

	[ -n "$device" ] || {
		echo "mbim[$$]" "No control device specified"
		proto_notify_error "$interface" NO_DEVICE
		proto_set_available "$interface" 0
		return 1
	}
	[ -c "$device" ] || {
		echo "mbim[$$]" "The specified control device does not exist"
		proto_notify_error "$interface" NO_DEVICE
		proto_set_available "$interface" 0
		return 1
	}

	devname="$(basename "$device")"
	devpath="$(readlink -f /sys/class/usbmisc/$devname/device/ || readlink -f /sys/class/wwan/$devname/device/)"
	ifname="$( ls "$devpath"/net )"

	[ -n "$ifname" ] || {
		echo "mbim[$$]" "Failed to find matching interface"
		proto_notify_error "$interface" NO_IFNAME
		proto_set_available "$interface" 0
		return 1
	}

	[ -n "$apn" ] || {
		echo "mbim[$$]" "No APN specified"
		proto_notify_error "$interface" NO_APN
		return 1
	}

	# Clean up any stale umbim process locking cdc-wdm
	local p
	for p in $(pgrep -f "umbim.*$device" 2>/dev/null); do
		[ "$p" != "$$" ] && kill -9 "$p" 2>/dev/null
	done

	# Auto-sync modem APN to PDP Context 1 via AT port if available (ensures Sierra/Quectel match)
	local at_p=""
	for at_p in /dev/ttyUSB0 /dev/ttyUSB2 /dev/ttyUSB1; do
		if [ -c "$at_p" ]; then
			if command -v modem_lock_run >/dev/null 2>&1; then
				modem_lock_run timeout 2 sh -c "echo 'AT+CGDCONT=1,\"IPV4V6\",\"$apn\"' | atinout - '$at_p' -" >/dev/null 2>&1
				modem_lock_run timeout 2 sh -c "echo 'AT+CGDCONT=3,\"IPV4V6\",\"$apn\"' | atinout - '$at_p' -" >/dev/null 2>&1
			elif command -v atinout >/dev/null 2>&1; then
				timeout 2 sh -c "echo 'AT+CGDCONT=1,\"IPV4V6\",\"$apn\"' | atinout - '$at_p' -" >/dev/null 2>&1
				timeout 2 sh -c "echo 'AT+CGDCONT=3,\"IPV4V6\",\"$apn\"' | atinout - '$at_p' -" >/dev/null 2>&1
			elif command -v sms_tool >/dev/null 2>&1; then
				timeout 2 sms_tool -d "$at_p" at "AT+CGDCONT=1,\"IPV4V6\",\"$apn\"" >/dev/null 2>&1
			fi
			break
		fi
	done

	[ -n "$delay" ] && sleep "$delay"

	echo "mbim[$$]" "Reading capabilities"
	local caps_try=0
	while [ $caps_try -lt 10 ]; do
		umbim $DBG -n -d $device caps >/dev/null 2>&1 && break
		caps_try=$((caps_try + 1))
		sleep 2
	done
	if [ $caps_try -ge 10 ]; then
		echo "mbim[$$]" "Modem caps not ready yet, soft retrying without resetting hardware..."
		proto_notify_error "$interface" NOT_READY
		return 1
	fi
	tid=$((tid + 1))

	[ "$pincode" ] && {
		echo "mbim[$$]" "Sending pin"
		umbim $DBG -n -t $tid -d $device unlock "$pincode" || {
			echo "mbim[$$]" "Unable to verify PIN"
			tid=$((tid + 1))
			proto_notify_error "$interface" PIN_FAILED
			proto_block_restart "$interface"
			return 1
		}
		tid=$((tid + 1))
	}

	echo "mbim[$$]" "Checking pin"
	umbim $DBG -n -t $tid -d $device pinstate
	[ $? -eq 2 ] && {
		echo "mbim[$$]" "PIN required"
		tid=$((tid + 1))
		proto_notify_error "$interface" PIN_FAILED
		proto_block_restart "$interface"
		return 1
	}
	tid=$((tid + 1))

	echo "mbim[$$]" "Checking subscriber"
	local sub_try=0
	while [ $sub_try -lt 5 ]; do
		umbim $DBG -n -t $tid -d $device subscriber && break
		tid=$((tid + 1))
		sub_try=$((sub_try + 1))
		sleep 1
	done
	if [ $sub_try -ge 5 ]; then
		echo "mbim[$$]" "Subscriber init failed"
		proto_notify_error "$interface" NO_SUBSCRIBER
		return 1
	fi
	tid=$((tid + 1))

	echo "mbim[$$]" "Register with network (Fast-Polling)"
	connected=0
	local reg_try=0
	while [ $reg_try -lt 20 ]; do
		umbim $DBG -n -t $tid -d $device registration >/dev/null 2>&1
		reg_status=$?
		tid=$((tid + 1))
		case $reg_status in
			0)	echo "mbim[$$]" "Registered in home mode (try $((reg_try + 1)))"
				connected=1
				break;;
			4)	if [ "$allow_roaming" = "1" ]; then
					echo "mbim[$$]" "Registered in roaming mode"
					connected=1
					break
				fi;;
			5) 	if [ "$allow_partner" = "1" ]; then
					echo "mbim[$$]" "Registered in partner mode"
					connected=1
					break
				fi;;
		esac
		sleep 1
		reg_try=$((reg_try + 1))
	done
	if [ $connected -ne 1 ]; then
		echo "mbim[$$]" "Subscriber registration failed (code $reg_status)"
		proto_notify_error "$interface" NO_REGISTRATION
		return 1
	fi

	echo "mbim[$$]" "Attach to network (Fast-Polling)"
	local att_try=0
	local attached=0
	while [ $att_try -lt 10 ]; do
		if umbim $DBG -n -t $tid -d $device attach; then
			attached=1
			break
		fi
		tid=$((tid + 1))
		att_try=$((att_try + 1))
		sleep 1
	done
	tid=$((tid + 1))
	if [ $attached -ne 1 ]; then
		echo "mbim[$$]" "Failed to attach to network"
		proto_notify_error "$interface" ATTACH_FAILED
		return 1
	fi

	pdptype=$(echo "$pdptype" | awk '{print tolower($0)}')
	[ "$ipv6" = 0 ] && pdptype="ipv4"

	local req_pdptype=""
	[ "$pdptype" = "ipv4" -o "$pdptype" = "ipv6" -o "$pdptype" = "ipv4v6" ] && req_pdptype="$pdptype:"

	local connect_state
	echo "mbim[$$]" "Connect to network"
	connect_state=$(umbim $DBG -n -t $tid -d $device connect "$req_pdptype$apn" "$auth" "$username" "$password")
	local conn_res=$?
	tid=$((tid + 1))

	if [ $conn_res -ne 0 ]; then
		echo "mbim[$$]" "First bearer connect attempt returned $conn_res, testing APN fallback..."
		# Try fallback with plain APN
		connect_state=$(umbim $DBG -n -t $tid -d $device connect "$apn" "none")
		conn_res=$?
		tid=$((tid + 1))
	fi

	if [ $conn_res -ne 0 ]; then
		echo "mbim[$$]" "Failed to connect bearer"
		proto_notify_error "$interface" CONNECT_FAILED
		return 1
	fi

	echo "$connect_state"
	local iptype="$(echo "$connect_state" | grep iptype: | awk '{print $4}')"
	[ -z "$iptype" ] && iptype="ipv4v6"

	echo "mbim[$$]" "Connected"

	local zone="$(fw3 -q network "$interface" 2>/dev/null)"

	echo "mbim[$$]" "Setting up $ifname"
	local mbimconfig="$(umbim $DBG -n -t $tid -d $device config)"
	echo "$mbimconfig"
	tid=$((tid + 1))

	proto_init_update "$ifname" 1
	proto_send_update "$interface"

	[ -z "$dhcp" ] && dhcp="auto"
	[ -z "$dhcpv6" ] && dhcpv6="auto"

	[ "$iptype" != "ipv6" ] && {
		json_init
		json_add_string name "${interface}_4"
		json_add_string ifname "@$interface"
		ipv4address=$(_proto_mbim_get_field ipv4address "$mbimconfig")
		if [ -n "$ipv4address" -a "$dhcp" != 1 ]; then
			json_add_string proto "static"

			json_add_array ipaddr
			for address in $ipv4address; do
				json_add_string "" "$address"
			done
			json_close_array

			json_add_string gateway $(_proto_mbim_get_field ipv4gateway "$mbimconfig")
		elif [ "$dhcp" != 0 ]; then
			echo "mbim[$$]" "Starting DHCP on $ifname"
			json_add_string proto "dhcp"
		fi

		local dnsserver="$(_proto_mbim_get_field ipv4dnsserver "$mbimconfig")"
		[ -z "$dnsserver" ] && dnsserver="116.98.212.54 203.113.131.5 1.1.1.1 8.8.8.8"
		json_add_array dns
		for server in $dnsserver; do
			json_add_string "" "$server"
		done
		json_close_array

		proto_add_dynamic_defaults
		[ -n "$zone" ] && json_add_string zone "$zone"
		[ -n "$ip4table" ] && json_add_string ip4table "$ip4table"
		json_close_object
		ubus call network add_dynamic "$(json_dump)"
	}

	[ "$iptype" != "ipv4" ] && {
		json_init
		json_add_string name "${interface}_6"
		json_add_string ifname "@$interface"
		ipv6address=$(_proto_mbim_get_field ipv6address "$mbimconfig")
		if [ -n "$ipv6address" -a "$dhcpv6" != 1 ]; then
			json_add_string proto "static"

			json_add_array ip6addr
			for address in $ipv6address; do
				json_add_string "" "$address"
			done
			json_close_array

			json_add_array ip6prefix
			for address in $ipv6address; do
				json_add_string "" "$address"
			done
			json_close_array

			json_add_string ip6gw $(_proto_mbim_get_field ipv6gateway "$mbimconfig")

		elif [ "$dhcpv6" != 0 ]; then
			echo "mbim[$$]" "Starting DHCPv6 on $ifname"
			json_add_string proto "dhcpv6"
			json_add_string extendprefix 1
			[ "$delegate" = "0" ] && json_add_boolean delegate "0"
			[ "$sourcefilter" = "0" ] && json_add_boolean sourcefilter "0"
		fi

		local dns6server="$(_proto_mbim_get_field ipv6dnsserver "$mbimconfig")"
		[ -z "$dns6server" ] && dns6server="2606:4700:4700::1111 2001:4860:4860::8888"
		json_add_array dns
		for server in $dns6server; do
			json_add_string "" "$server"
		done
		json_close_array

		proto_add_dynamic_defaults
		[ -n "$zone" ] && json_add_string zone "$zone"
		[ -n "$ip6table" ] && json_add_string ip6table "$ip6table"
		json_close_object
		ubus call network add_dynamic "$(json_dump)"
	}

	[ -z "$mtu" ] && {
		local ipv4mtu=$(_proto_mbim_get_field ipv4mtu "$mbimconfig")
		ipv4mtu="${ipv4mtu:-0}"
		local ipv6mtu=$(_proto_mbim_get_field ipv6mtu "$mbimconfig")
		ipv6mtu="${ipv6mtu:-0}"

		mtu=$((ipv6mtu > ipv4mtu ? ipv6mtu : ipv4mtu))
	}
	[ -z "$mtu" ] || [ "$mtu" -le 0 ] && mtu=1460
	[ "$mtu" -gt 1460 ] && mtu=1460
	[ -n "$mtu" -a "$mtu" != 0 ] && {
		echo Setting MTU of $ifname to $mtu
		/sbin/ip link set dev $ifname mtu $mtu
	}

	uci_set_state network $interface tid "$tid"
}

proto_mbim_setup() {
	local ret

	_proto_mbim_setup $@
	ret=$?

	[ "$ret" = 0 ] || {
		logger "mbim bringup failed, fast retry in 2s"
		sleep 2
	}

	return $ret
}

proto_mbim_teardown() {
	local interface="$1"

	local device devpath
	json_get_vars device devpath
	local tid=$(uci_get_state network $interface tid)

	[ -n "$ctl_device" ] && device=$ctl_device

	if [ -n "$devpath" ]; then
		local usbmisc_or_wwan_path
		for usbmisc_or_wwan_path in \
		    "$devpath"/usbmisc/cdc-wdm* \
		    "$devpath"/*/usbmisc/cdc-wdm* \
		    "$devpath"/*/wwan[0-9]*/wwan[0-9]*mbim* \
		    "$devpath"/*/*/wwan[0-9]*/wwan[0-9]*mbim*; do
			device="/dev/${usbmisc_or_wwan_path##*/}"
		done
	fi

	echo "mbim[$$]" "Stopping network"
	[ -n "$tid" ] && {
		# Disconnect with 3-second safety timeout so it never hangs
		( sleep 3 && killall -9 umbim 2>/dev/null ) &
		local killer_pid=$!
		umbim $DBG -n -t $tid -d "$device" disconnect 2>/dev/null
		kill "$killer_pid" 2>/dev/null
		uci_revert_state network $interface tid
	}

	proto_init_update "*" 0
	proto_send_update "$interface"
}

[ -n "$INCLUDE_ONLY" ] || add_protocol mbim
