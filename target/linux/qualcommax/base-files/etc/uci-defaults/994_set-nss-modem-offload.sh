#!/bin/sh
# NSS Hardware Offload & Cellular Modem Optimization for JDCloud Athena AX6600
# Copyright (C) 2026 Antigravity for Anh Duy (DOANDUY)

# 1. Disable software/hardware flow offloading in firewall to let NSS-ECM handle 100% of flows
uci -q batch <<EOF
set firewall.@defaults[0].flow_offloading='0'
set firewall.@defaults[0].flow_offloading_hw='0'
commit firewall
EOF

# 2. Disable packet steering to prevent IPI latency and CPU ring buffer thrashing
uci -q batch <<EOF
set network.globals.packet_steering='0'
del network.globals.steering_flows
commit network
EOF

# 3. Configure ECM for NSS acceleration
if [ -f /etc/config/ecm ]; then
    uci -q batch <<EOF
set ecm.global.acceleration_engine='nss'
set ecm.general.enable_bridge_filtering='0'
commit ecm
EOF
fi

# 4. Apply high-performance sysctl settings
SYSCTL_CONF="/etc/sysctl.d/99-nss-modem.conf"
cat <<EOF > "$SYSCTL_CONF"
dev.nss.general.redirect=1
net.bridge.bridge-nf-call-iptables=0
net.bridge.bridge-nf-call-ip6tables=0
net.bridge.bridge-nf-call-arptables=0
net.core.rps_sock_flow_entries=0
net.netfilter.nf_conntrack_max=65535
EOF

sysctl -p "$SYSCTL_CONF" 2>/dev/null || true

[ -x /etc/init.d/athena_storage ] && /etc/init.d/athena_storage enable
exit 0
