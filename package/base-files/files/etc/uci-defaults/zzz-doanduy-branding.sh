#!/bin/sh
# Final branding enforcement (runs after 99-default-settings* & 999_* so LibWrt/ImmortalWrt defaults never override DOANDUY)

# 1. Hostname, Timezone (GMT+7) & Global Fast NTP (revert any CN mirror/NTP override)
uci -q set system.@system[0].hostname='DOANDUY'
uci -q set system.@system[0].zonename='Asia/Ho_Chi_Minh'
uci -q set system.@system[0].timezone='<+07>-7'
uci -q delete system.ntp.server
uci -q add_list system.ntp.server='time.cloudflare.com'
uci -q add_list system.ntp.server='time1.google.com'
uci -q add_list system.ntp.server='vn.pool.ntp.org'
uci -q add_list system.ntp.server='pool.ntp.org'
uci -q commit system

if [ -f /etc/apk/repositories.d/distfeeds.list.bak ]; then
    mv -f /etc/apk/repositories.d/distfeeds.list.bak /etc/apk/repositories.d/distfeeds.list 2>/dev/null || true
fi

# 2. LuCI Language (Vietnamese) & Argon Theme
uci -q set luci.main.lang='vi'
uci -q set luci.main.mediaurlbase='/luci-static/argon'
uci -q set luci.themes.Argon='/luci-static/argon'
uci -q commit luci

# 3. Unified Wi-Fi SSID Branding (DOANDUY_2.4G / DOANDUY_5G / DOANDUY_6G)
[ -x /sbin/wifi ] && /sbin/wifi config >/dev/null 2>&1 || true
for ifc in $(uci -q show wireless | sed -n 's/^wireless\.\([^.=]*\)=wifi-iface$/\1/p'); do
    dev=$(uci -q get "wireless.${ifc}.device")
    band=$(uci -q get "wireless.${dev}.band")
    case "$band" in
        2g) ssid="DOANDUY_2.4G" ;;
        5g) ssid="DOANDUY_5G" ;;
        6g) ssid="DOANDUY_6G" ;;
        *)  ssid="DOANDUY" ;;
    esac
    uci -q set "wireless.${ifc}.ssid=${ssid}"
    uci -q set "wireless.${ifc}.disabled=0"
done
uci -q commit wireless

exit 0
