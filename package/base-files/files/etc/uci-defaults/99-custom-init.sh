#!/bin/sh
# Custom system initialization and tuning script

# 1. TCP BBR & Kernel Performance tuning
if [ -f /etc/sysctl.d/99-custom-tuning.conf ]; then
    sysctl -p /etc/sysctl.d/99-custom-tuning.conf 2>/dev/null
fi

# 2. Timezone & NTP setup (Asia/Ho_Chi_Minh - UTC+7)
uci -q set system.@system[0].zonename='Asia/Ho_Chi_Minh'
uci -q set system.@system[0].timezone='<+07>-7'
uci commit system 2>/dev/null

# 3. Enable Hardware Flow Offloading (MediaTek / Qualcomm NSS)
uci -q set firewall.@defaults[0].flow_offloading='1'
uci -q set firewall.@defaults[0].flow_offloading_hw='1'
uci commit firewall 2>/dev/null

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

# 6. Enable Master / all service
if [ -f /etc/init.d/all ]; then
    /etc/init.d/all enable 2>/dev/null
fi

# 7. Set default LuCI Theme to Argon for ALL routers
uci -q batch <<-EOF
	set luci.main.mediaurlbase=/luci-static/argon
	set luci.themes.Argon=/luci-static/argon
	commit luci
EOF

# 8. Clean up conflicting legacy menu entries (AT commands, SMS, Usteer, Easymesh) and redundant services
rm -f /usr/share/luci/menu.d/luci-app-atcommands.json \
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
