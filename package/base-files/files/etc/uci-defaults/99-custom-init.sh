#!/bin/sh
# Custom First-Boot Initialization for JDCloud RE-CS-02 (Duydoan-24.10)

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

# 4. Silence distant camera 802.11 unacknowledged frame log flooding
uci -q set wireless.radio0.log_level='3'
uci -q set wireless.radio0.log_80211='0'
uci -q set wireless.radio1.log_level='3'
uci -q set wireless.radio1.log_80211='0'
uci -q set wireless.radio2.log_level='3'
uci -q set wireless.radio2.log_80211='0'
uci commit wireless 2>/dev/null

# 5. Set WWAN0 delay 5s for stable MBIM initialization
uci -q set network.wwan0.delay='5'
uci commit network 2>/dev/null

# 6. Enable Master / all service
if [ -f /etc/init.d/all ]; then
    /etc/init.d/all enable 2>/dev/null
fi

exit 0
