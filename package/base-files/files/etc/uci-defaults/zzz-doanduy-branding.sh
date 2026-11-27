#!/bin/sh
# Final branding enforcement (runs after 99-default-settings* so LibWrt/ImmortalWrt defaults never override DOANDUY)

# 1. Hostname & Timezone (GMT+7)
uci -q set system.@system[0].hostname='DOANDUY'
uci -q set system.@system[0].zonename='Asia/Ho_Chi_Minh'
uci -q set system.@system[0].timezone='<+07>-7'
uci -q commit system

# 2. LuCI Language (Vietnamese) & Argon Theme
uci -q set luci.main.lang='vi'
uci -q set luci.main.mediaurlbase='/luci-static/argon'
uci -q set luci.themes.Argon='/luci-static/argon'
uci -q commit luci

# 3. Unified Wi-Fi SSID Branding (DOANDUY_2.4G / DOANDUY_5G)
for ifc in $(uci -q show wireless | sed -n 's/^wireless\.\([^.=]*\)=wifi-iface$/\1/p'); do
    dev=$(uci -q get "wireless.${ifc}.device")
    band=$(uci -q get "wireless.${dev}.band")
    case "$band" in
        2g) ssid="DOANDUY_2.4G" ;;
        5g|6g) ssid="DOANDUY_5G" ;;
        *) ssid="DOANDUY" ;;
    esac
    uci -q set "wireless.${ifc}.ssid=${ssid}"
    uci -q set "wireless.${ifc}.disabled=0"
done
uci -q commit wireless

exit 0
