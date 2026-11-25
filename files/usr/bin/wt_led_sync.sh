#!/bin/sh
# ==============================================================================
# Wireless-Tag ZX7981PD (5G CPE) Smart LED Manager
# ==============================================================================

[ "$(cat /tmp/sysinfo/board_name 2>/dev/null)" = "wirelesstag,zx7981pd" ] || exit 0

LED_4G_B="/sys/class/leds/wt:4g:blue"
LED_4G_Y="/sys/class/leds/wt:4g:yellow"
LED_5G_B="/sys/class/leds/wt:5g:blue"
LED_5G_Y="/sys/class/leds/wt:5g:yellow"

[ -d "$LED_4G_B" ] || exit 0

update_leds() {
    local cell_if=""
    for iface in eth2 wwan0 usb0 rmnet_mhi0; do
        if [ -d "/sys/class/net/$iface" ]; then
            cell_if="$iface"
            break
        fi
    done

    local rf_json="/tmp/rf_signal_stats.json"
    local has_5g=0
    local has_4g=0
    local grade_5g="good"
    local grade_4g="good"

    if [ -f "$rf_json" ]; then
        local nr_band=$(jsonfilter -i "$rf_json" -e '$.nr5g.band' 2>/dev/null)
        local lte_band=$(jsonfilter -i "$rf_json" -e '$.lte.band' 2>/dev/null)
        local status=$(jsonfilter -i "$rf_json" -e '$.status' 2>/dev/null)
        local score=$(jsonfilter -i "$rf_json" -e '$.score' 2>/dev/null || echo 100)

        if [ "$status" = "ok" ]; then
            if [ -n "$nr_band" ] && [ "$nr_band" != "--" ] && [ "$nr_band" != "Không có thiết bị" ]; then
                has_5g=1
            fi
            if [ -n "$lte_band" ] && [ "$lte_band" != "--" ] && [ "$lte_band" != "Không có thiết bị" ]; then
                has_4g=1
            fi
            case "$score" in ''|*[!0-9]*) score=100 ;; esac
            if [ "$score" -lt 60 ]; then
                grade_5g="weak"
                grade_4g="weak"
            fi
        fi
    fi

    if [ -n "$cell_if" ] && [ $has_5g -eq 0 ] && [ $has_4g -eq 0 ]; then
        has_5g=1
        has_4g=1
    fi

    # 1. Dieu khien LED 5G
    if [ $has_5g -eq 1 ]; then
        if [ "$grade_5g" = "weak" ]; then
            echo none > "$LED_5G_B/trigger" 2>/dev/null
            echo 0 > "$LED_5G_B/brightness" 2>/dev/null
            echo 1 > "$LED_5G_Y/brightness" 2>/dev/null
        else
            echo 0 > "$LED_5G_Y/brightness" 2>/dev/null
            if [ -n "$cell_if" ]; then
                local cur_trig=$(cat "$LED_5G_B/trigger" 2>/dev/null)
                case "$cur_trig" in
                    *"[netdev]"*) ;;
                    *)
                        echo netdev > "$LED_5G_B/trigger" 2>/dev/null
                        echo "$cell_if" > "$LED_5G_B/device_name" 2>/dev/null
                        echo 1 > "$LED_5G_B/link" 2>/dev/null
                        echo 1 > "$LED_5G_B/rx" 2>/dev/null
                        echo 1 > "$LED_5G_B/tx" 2>/dev/null
                        ;;
                esac
            else
                echo 1 > "$LED_5G_B/brightness" 2>/dev/null
            fi
        fi
    else
        echo none > "$LED_5G_B/trigger" 2>/dev/null
        echo 0 > "$LED_5G_B/brightness" 2>/dev/null
        echo 0 > "$LED_5G_Y/brightness" 2>/dev/null
    fi

    # 2. Dieu khien LED 4G
    if [ $has_4g -eq 1 ]; then
        if [ "$grade_4g" = "weak" ]; then
            echo none > "$LED_4G_B/trigger" 2>/dev/null
            echo 0 > "$LED_4G_B/brightness" 2>/dev/null
            echo 1 > "$LED_4G_Y/brightness" 2>/dev/null
        else
            echo 0 > "$LED_4G_Y/brightness" 2>/dev/null
            if [ -n "$cell_if" ]; then
                local cur_trig=$(cat "$LED_4G_B/trigger" 2>/dev/null)
                case "$cur_trig" in
                    *"[netdev]"*) ;;
                    *)
                        echo netdev > "$LED_4G_B/trigger" 2>/dev/null
                        echo "$cell_if" > "$LED_4G_B/device_name" 2>/dev/null
                        echo 1 > "$LED_4G_B/link" 2>/dev/null
                        echo 1 > "$LED_4G_B/rx" 2>/dev/null
                        echo 1 > "$LED_4G_B/tx" 2>/dev/null
                        ;;
                esac
            else
                echo 1 > "$LED_4G_B/brightness" 2>/dev/null
            fi
        fi
    else
        echo none > "$LED_4G_B/trigger" 2>/dev/null
        echo 0 > "$LED_4G_B/brightness" 2>/dev/null
        echo 0 > "$LED_4G_Y/brightness" 2>/dev/null
    fi
}

if [ "$1" = "daemon" ]; then
    while true; do
        update_leds
        sleep 10
    done
else
    update_leds
fi
