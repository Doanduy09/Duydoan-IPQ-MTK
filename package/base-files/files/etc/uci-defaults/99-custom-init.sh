#!/bin/sh
# Custom First-Boot Initialization for JDCloud RE-CS-02 (Duydoan-24.10)

# 0. Upgrade HNAT Toggle Button in Master Script
if [ -f /etc/init.d/all ] && command -v lua >/dev/null 2>&1; then
    lua /etc/uci-defaults/patch_hnat.lua /etc/init.d/all >/dev/null 2>&1
fi

# 1. Symlink /usr/bin/all and /etc/init.d/all to sysfixtine
if [ -f /etc/init.d/all ] && [ ! -f /usr/bin/sysfixtine ]; then
    cp -f /etc/init.d/all /usr/bin/sysfixtine
    chmod 755 /usr/bin/sysfixtine
fi

if [ -f /usr/bin/sysfixtine ]; then
    ln -sf /usr/bin/sysfixtine /usr/bin/all
    ln -sf /usr/bin/sysfixtine /etc/init.d/all
    chmod 755 /usr/bin/all /etc/init.d/all 2>/dev/null
fi

# 2. Prevent ModemManager from conflicting with MBIM on /dev/cdc-wdm0
if [ -f /etc/init.d/modemmanager ]; then
    /etc/init.d/modemmanager disable 2>/dev/null
    /etc/init.d/modemmanager stop 2>/dev/null
fi
[ -f /usr/libexec/mbim-proxy ] && chmod 000 /usr/libexec/mbim-proxy 2>/dev/null

# 3. Hardware Flow Offload by default
uci -q set firewall.@defaults[0].flow_offloading='1'
uci -q set firewall.@defaults[0].flow_offloading_hw='1'
uci commit firewall 2>/dev/null

# 4. Boost Wi-Fi TX Power (30dBm / 1000mW), Beamforming & Silence log flood
for rad in radio0 radio1 radio2; do
    if uci -q get wireless.${rad} >/dev/null 2>&1; then
        uci -q set wireless.${rad}.country='US'
        uci -q set wireless.${rad}.txpower='30'
        uci -q set wireless.${rad}.he_su_beamformer='1'
        uci -q set wireless.${rad}.he_su_beamformee='1'
        uci -q set wireless.${rad}.he_mu_beamformer='1'
        uci -q set wireless.${rad}.log_level='3'
        uci -q set wireless.${rad}.log_80211='0'
    fi
done
uci commit wireless 2>/dev/null

# 5. Set WWAN0 delay 5s for stable MBIM initialization
uci -q set network.wwan0.delay='5'
uci commit network 2>/dev/null

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

# 8. Clean up conflicting legacy modem/SMS menu entries and irqbalance
rm -f /usr/share/luci/menu.d/luci-app-3ginfo-lite.json \
      /usr/share/luci/menu.d/luci-app-sms-tool-js.json \
      /etc/uci-defaults/setup_sms_tool_js.sh \
      /etc/uci-defaults/set_3ginfo_port.sh \
      /etc/init.d/my_new_sms 2>/dev/null
if [ -f /etc/init.d/irqbalance ]; then
    /etc/init.d/irqbalance disable 2>/dev/null
    /etc/init.d/irqbalance stop 2>/dev/null
fi

exit 0
