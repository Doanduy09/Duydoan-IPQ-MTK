#!/bin/sh
# Custom system initialization and tuning script (duydoan5g dialer authoritative — legacy /etc/init.d/all removed)

# 1. TCP BBR & Kernel Performance tuning
if [ -f /etc/sysctl.d/99-custom-tuning.conf ]; then
    sysctl -p /etc/sysctl.d/99-custom-tuning.conf 2>/dev/null
fi

# 2. Timezone & NTP setup (Asia/Ho_Chi_Minh - UTC+7)
uci -q set system.@system[0].zonename='Asia/Ho_Chi_Minh'
uci -q set system.@system[0].timezone='<+07>-7'
uci commit system 2>/dev/null

# [VERIFIED-GOLDEN: offload-soc-isolation | 2026-11-26 | DO NOT MODIFY UNLESS TARGETED]
# 3. Enable Hardware Flow Offloading only on non-NSS / non-mt_wifi+HNAT targets
if [ -d /sys/module/qca_nss_drv ] || ls /etc/modules.d/*qca-nss* >/dev/null 2>&1; then
    uci -q set firewall.@defaults[0].flow_offloading='0'
    uci -q set firewall.@defaults[0].flow_offloading_hw='0'
elif [ -d /sys/module/mt_wifi ] || ls /etc/modules.d/*mt_wifi* /etc/modules.d/*hnat* >/dev/null 2>&1; then
    uci -q set firewall.@defaults[0].flow_offloading='0'
    uci -q set firewall.@defaults[0].flow_offloading_hw='0'
else
    uci -q set firewall.@defaults[0].flow_offloading='1'
    uci -q set firewall.@defaults[0].flow_offloading_hw='1'
fi
uci commit firewall 2>/dev/null
# [/VERIFIED-GOLDEN]

# 4. Boost Wi-Fi TX Power (30dBm / 1000mW), Beamforming & Silence log flood
for rad in radio0 radio1 radio2; do
    if uci -q get wireless.${rad} >/dev/null 2>&1; then
        uci -q set wireless.${rad}.disabled='0'
        uci -q set wireless.${rad}.country='US'
        uci -q set wireless.${rad}.txpower='30'
        uci -q set wireless.${rad}.he_su_beamformer='1'
        uci -q set wireless.${rad}.he_su_beamformee='1'
        uci -q set wireless.${rad}.he_mu_beamformer='1'
        uci -q set wireless.${rad}.log_level='3'
        uci -q set wireless.${rad}.log_80211='0'
    fi
done
for ifc in default_radio0 default_radio1 default_radio2; do
    if uci -q get wireless.${ifc} >/dev/null 2>&1; then
        uci -q set wireless.${ifc}.disabled='0'
    fi
done
uci commit wireless 2>/dev/null

# 5. Set WWAN0 delay 5s for stable MBIM initialization
if uci -q get network.wwan0 >/dev/null 2>&1; then
    uci -q set network.wwan0.delay='5'
    uci commit network 2>/dev/null
fi

# 6. Set default LuCI Theme to Argon & default language to Vietnamese for ALL routers
uci -q batch <<-EOF
	set luci.main.mediaurlbase=/luci-static/argon
	set luci.themes.Argon=/luci-static/argon
	set luci.main.lang=vi
	commit luci
EOF

# 7. Clean up conflicting legacy menu entries & services (including any leftover /etc/init.d/all)
rm -f /etc/init.d/all \
      /usr/share/luci/menu.d/luci-app-atcommands.json \
      /usr/share/luci/menu.d/luci-app-sms-tool-js.json \
      /usr/share/luci/menu.d/luci-app-usteer.json \
      /usr/share/luci/menu.d/luci-app-easymesh.json \
      /usr/share/luci/menu.d/luci-app-3ginfo-lite.json \
      /etc/uci-defaults/setup_sms_tool_js.sh \
      /etc/uci-defaults/set_3ginfo_port.sh \
      /etc/init.d/my_new_sms \
      /etc/init.d/easymesh \
      /etc/init.d/usteer 2>/dev/null
if [ -f /etc/init.d/easymesh ]; then
    /etc/init.d/easymesh disable 2>/dev/null
    /etc/init.d/easymesh stop 2>/dev/null
fi
if [ -f /etc/init.d/usteer ]; then
    /etc/init.d/usteer disable 2>/dev/null
    /etc/init.d/usteer stop 2>/dev/null
fi
if [ -f /etc/init.d/irqbalance ]; then
    /etc/init.d/irqbalance disable 2>/dev/null
    /etc/init.d/irqbalance stop 2>/dev/null
fi

exit 0
