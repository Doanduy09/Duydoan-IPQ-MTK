#!/bin/sh
# Hotplug for wwan network interfaces (wwan0, usb0)
[ "$ACTION" = "add" ] || [ "$ACTION" = "ifup" ] || exit 0

case "$INTERFACE" in
    wwan*|usb*)
        # 1. Toi uu RPS & Flow Steering phan phoi sang Core 2 & Core 3
        if [ -d "/sys/class/net/$INTERFACE/queues/rx-0" ]; then
            echo c > "/sys/class/net/$INTERFACE/queues/rx-0/rps_cpus" 2>/dev/null
            echo 4096 > "/sys/class/net/$INTERFACE/queues/rx-0/rps_flow_cnt" 2>/dev/null
            echo 32768 > /proc/sys/net/core/rps_sock_flow_entries 2>/dev/null
        fi

        # 2. Tach ngat phan cung USB 3.0 XHCI sang Core 1
        for irq_f in /proc/irq/*/xhci-hcd*; do
            if [ -d "$irq_f" ]; then
                irq_num=$(basename $(dirname "$irq_f"))
                [ -f "/proc/irq/$irq_num/smp_affinity" ] && echo 2 > "/proc/irq/$irq_num/smp_affinity" 2>/dev/null
            fi
        done
        for x_irq in $(awk -F: '/xhci/ {gsub(/ /, "", $1); print $1}' /proc/interrupts 2>/dev/null); do
            [ -f "/proc/irq/$x_irq/smp_affinity" ] && echo 2 > "/proc/irq/$x_irq/smp_affinity" 2>/dev/null
        done

        # 3. Tu dong kiem tra va khoi dong interface
        (
            sleep 1
            if command -v ubus >/dev/null 2>&1; then
                for iface in wwan0 usb0; do
                    up=$(ubus call network.interface.$iface status 2>/dev/null | jsonfilter -e '@.up' 2>/dev/null)
                    if [ "$up" != "true" ]; then
                        ubus call network.interface.$iface up 2>/dev/null || ifup "$iface" 2>/dev/null
                    fi
                done
            fi
        ) &
        ;;
esac

