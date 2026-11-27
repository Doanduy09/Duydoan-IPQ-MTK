#!/bin/sh
# [VERIFIED-GOLDEN: unified-ipq-mtk-kmod-master | 2026-11-27 | SINGLE SOURCE OF TRUTH ACROSS ALL 4 BRANCHES]
# Unified Master Kmod, Firmware & Userspace Standard for ALL Qualcomm IPQ & MediaTek Filogic Routers
# Audited against 25 reference .config/.manifest files in Desktop/Rom wifi & all 4 branches (K6.12 & K6.18)
set -e

CFG="${1:-.config}"
[ -f "$CFG" ] || exit 0

cat << 'EOF' >> "$CFG"
# ==============================================================================
# [A] COMMON MANDATORY KMODS & TOOLS (SHARED 1:1 ACROSS ALL IPQ & MTK ROUTERS)
# ==============================================================================

# --- 1. USB Host Controllers, Hub, HID & Modeswitch ---
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-usb-ehci=y
CONFIG_PACKAGE_kmod-usb-ohci=y
CONFIG_PACKAGE_kmod-usb-uhci=y
CONFIG_PACKAGE_kmod-usb-dwc2=y
CONFIG_PACKAGE_kmod-usb-dwc3=y
CONFIG_PACKAGE_kmod-usb-roles=y
CONFIG_PACKAGE_kmod-usb-hid=y
CONFIG_PACKAGE_kmod-usb-ledtrig-usbport=y
CONFIG_PACKAGE_usb-modeswitch=y
CONFIG_PACKAGE_usbutils=y

# --- 2. PCIe 5G Modem (MHI Bus/Net/AT-QMI-Ctrl/MBIM, MediaTek T7xx, QRTR & RMNET) ---
CONFIG_PACKAGE_kmod-wwan=y
CONFIG_PACKAGE_kmod-mhi-bus=y
CONFIG_PACKAGE_kmod-mhi-pci-generic=y
CONFIG_PACKAGE_kmod-mhi-net=y
CONFIG_PACKAGE_kmod-mhi-wwan-ctrl=y
CONFIG_PACKAGE_kmod-mhi-wwan-mbim=y
CONFIG_PACKAGE_kmod-mtk-t7xx=y
CONFIG_PACKAGE_kmod-qrtr=y
CONFIG_PACKAGE_kmod-qrtr-mhi=y
CONFIG_PACKAGE_kmod-qrtr-tun=y
CONFIG_PACKAGE_kmod-rmnet=y
CONFIG_PACKAGE_pciutils=y

# --- 3. USB 4G/5G Modem, USB-to-LAN & iPhone/Android Tethering ---
CONFIG_PACKAGE_kmod-usb-net-qmi-wwan=y
CONFIG_PACKAGE_kmod-usb-net-qmi-wwan-fibocom=y
CONFIG_PACKAGE_kmod-usb-net-qmi-wwan-quectel=y
CONFIG_PACKAGE_kmod-usb-net-cdc-mbim=y
CONFIG_PACKAGE_kmod-usb-net-cdc-ncm=y
CONFIG_PACKAGE_kmod-usb-net-huawei-cdc-ncm=y
CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y
CONFIG_PACKAGE_kmod-usb-net-cdc-eem=y
CONFIG_PACKAGE_kmod-usb-net-cdc-subset=y
CONFIG_PACKAGE_kmod-usb-net-rndis=y
CONFIG_PACKAGE_kmod-usb-net-sierrawireless=y
CONFIG_PACKAGE_kmod-usb-net-hso=y
CONFIG_PACKAGE_kmod-usb-net-kalmia=y
CONFIG_PACKAGE_kmod-usb-net-ipheth=y
CONFIG_PACKAGE_kmod-usb-net-rtl8152=y
CONFIG_PACKAGE_kmod-usb-net-rtl8150=y
CONFIG_PACKAGE_kmod-usb-net-asix=y
CONFIG_PACKAGE_kmod-usb-net-asix-ax88179=y
CONFIG_PACKAGE_kmod-usb-net-aqc111=y
CONFIG_PACKAGE_kmod-usb-net-lan78xx=y
CONFIG_PACKAGE_kmod-usb-net-smsc75xx=y
CONFIG_PACKAGE_kmod-usb-net-smsc95xx=y
CONFIG_PACKAGE_kmod-usb-net-dm9601-ether=y
CONFIG_PACKAGE_kmod-usb-net-sr9700=y
CONFIG_PACKAGE_kmod-usb-net-mcs7830=y
CONFIG_PACKAGE_kmod-usb-net-pegasus=y
CONFIG_PACKAGE_kmod-usb-net-kaweth=y
CONFIG_PACKAGE_kmod-usb-net-pl=y
CONFIG_PACKAGE_kmod-phy-aquantia=y

# --- 4. USB Serial / AT / UART Debug ---
CONFIG_PACKAGE_kmod-usb-serial-option=y
CONFIG_PACKAGE_kmod-usb-serial-wwan=y
CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y
CONFIG_PACKAGE_kmod-usb-serial-sierrawireless=y
CONFIG_PACKAGE_kmod-usb-serial-simple=y
CONFIG_PACKAGE_kmod-usb-serial-ti-usb=y
CONFIG_PACKAGE_kmod-usb-serial-cp210x=y
CONFIG_PACKAGE_kmod-usb-serial-ch341=y
CONFIG_PACKAGE_kmod-usb-serial-ch348=y
CONFIG_PACKAGE_kmod-usb-serial-ftdi=y
CONFIG_PACKAGE_kmod-usb-serial-pl2303=y
CONFIG_PACKAGE_kmod-usb-acm=y
CONFIG_PACKAGE_kmod-usb-wdm=y

# --- 5. Storage, Filesystems (/overlay F2FS + USB/NVMe), ZRAM & Crash Recovery ---
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_kmod-usb-storage-extras=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-f2fs=y
CONFIG_PACKAGE_kmod-fs-autofs4=y
CONFIG_PACKAGE_kmod-zram=y
CONFIG_PACKAGE_zram-swap=y
CONFIG_PACKAGE_kmod-ramoops=y
CONFIG_PACKAGE_kmod-pstore=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_e2fsprogs=y
CONFIG_PACKAGE_mkf2fs=y
CONFIG_PACKAGE_f2fsck=y
CONFIG_PACKAGE_losetup=y
CONFIG_PACKAGE_uboot-envtools=y

# --- 6. Router Buttons (Reset/WPS/Mesh), LEDs, Thermal, Fan & I2C Hardware ---
CONFIG_PACKAGE_kmod-gpio-button-hotplug=y
CONFIG_PACKAGE_kmod-input-core=y
CONFIG_PACKAGE_kmod-input-evdev=y
CONFIG_PACKAGE_kmod-leds-gpio=y
CONFIG_PACKAGE_kmod-leds-pwm=y
CONFIG_PACKAGE_kmod-thermal=y
CONFIG_PACKAGE_kmod-hwmon-core=y
CONFIG_PACKAGE_kmod-hwmon-pwmfan=y
CONFIG_PACKAGE_kmod-hwmon-gpiofan=y
CONFIG_PACKAGE_kmod-i2c-core=y
CONFIG_PACKAGE_kmod-i2c-gpio=y
CONFIG_PACKAGE_kmod-eeprom-at24=y

# --- 7. Crypto, Flow Offload, Netfilter, TTL/HL Anti-Throttling, QoS & VPN/WAN Tunnels ---
CONFIG_PACKAGE_kmod-crypto-aead=y
CONFIG_PACKAGE_kmod-crypto-arc4=y
CONFIG_PACKAGE_kmod-crypto-authenc=y
CONFIG_PACKAGE_kmod-crypto-ccm=y
CONFIG_PACKAGE_kmod-crypto-cmac=y
CONFIG_PACKAGE_kmod-crypto-crc32c=y
CONFIG_PACKAGE_kmod-crypto-ctr=y
CONFIG_PACKAGE_kmod-crypto-des=y
CONFIG_PACKAGE_kmod-crypto-ecb=y
CONFIG_PACKAGE_kmod-crypto-gcm=y
CONFIG_PACKAGE_kmod-crypto-gf128=y
CONFIG_PACKAGE_kmod-crypto-ghash=y
CONFIG_PACKAGE_kmod-crypto-hmac=y
CONFIG_PACKAGE_kmod-crypto-manager=y
CONFIG_PACKAGE_kmod-crypto-md4=y
CONFIG_PACKAGE_kmod-crypto-md5=y
CONFIG_PACKAGE_kmod-crypto-michael-mic=y
CONFIG_PACKAGE_kmod-crypto-null=y
CONFIG_PACKAGE_kmod-crypto-rng=y
CONFIG_PACKAGE_kmod-crypto-seqiv=y
CONFIG_PACKAGE_kmod-crypto-sha1=y
CONFIG_PACKAGE_kmod-crypto-sha256=y
CONFIG_PACKAGE_kmod-crypto-sha512=y
CONFIG_PACKAGE_kmod-crypto-user=y
CONFIG_PACKAGE_kmod-nft-offload=y
CONFIG_PACKAGE_kmod-nf-flow=y
CONFIG_PACKAGE_kmod-nft-compat=y
CONFIG_PACKAGE_kmod-nft-fullcone=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-nft-connlimit=y
CONFIG_PACKAGE_kmod-nf-conntrack6=y
CONFIG_PACKAGE_kmod-nf-conntrack-netlink=y
CONFIG_PACKAGE_kmod-nf-conncount=y
CONFIG_PACKAGE_kmod-nf-nathelper=y
CONFIG_PACKAGE_kmod-nf-nathelper-extra=y
CONFIG_PACKAGE_kmod-inet-diag=y
CONFIG_PACKAGE_kmod-netlink-diag=y
CONFIG_PACKAGE_kmod-ipt-ipopt=y
CONFIG_PACKAGE_iptables-nft=y
CONFIG_PACKAGE_ip6tables-nft=y
CONFIG_PACKAGE_iptables-mod-ipopt=y
CONFIG_PACKAGE_kmod-tcp-bbr=y
CONFIG_PACKAGE_kmod-ifb=y
CONFIG_PACKAGE_kmod-sched-cake=y
CONFIG_PACKAGE_kmod-sched-flower=y
CONFIG_PACKAGE_kmod-sched-act-vlan=y
CONFIG_PACKAGE_kmod-sched-bpf=y
CONFIG_PACKAGE_kmod-crypto-blake2b=y
CONFIG_PACKAGE_kmod-crypto-xxhash=y
CONFIG_PACKAGE_kmod-lib-xxhash=y
CONFIG_PACKAGE_kmod-lib-zstd=y
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppoe=y
CONFIG_PACKAGE_kmod-pppol2tp=y
CONFIG_PACKAGE_kmod-l2tp=y
CONFIG_PACKAGE_kmod-pptp=y
CONFIG_PACKAGE_kmod-mppe=y
CONFIG_PACKAGE_kmod-gre=y
CONFIG_PACKAGE_kmod-gre6=y
CONFIG_PACKAGE_kmod-sit=y
CONFIG_PACKAGE_kmod-ip6-tunnel=y
CONFIG_PACKAGE_kmod-ipip=y
CONFIG_PACKAGE_kmod-nat46=y
CONFIG_PACKAGE_464xlat=y
CONFIG_PACKAGE_kmod-dummy=y
CONFIG_PACKAGE_kmod-batman-adv=y
CONFIG_PACKAGE_kmod-wireguard=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_kmod-veth=y
CONFIG_PACKAGE_kmod-vxlan=y
CONFIG_PACKAGE_kmod-bonding=y
CONFIG_PACKAGE_kmod-macvlan=y
CONFIG_PACKAGE_kmod-usb-serial-xr=y
CONFIG_PACKAGE_kmod-usb-printer=y
CONFIG_PACKAGE_kmod-usbmon=y

# --- 8. Fast 5G Dialers (quectel-cm + uqmi + umbim + atinout), Auto-Mesh Tools & LuCI VI ---
CONFIG_PACKAGE_quectel-cm-5g=y
CONFIG_PACKAGE_atinout=y
CONFIG_PACKAGE_umbim=y
CONFIG_PACKAGE_uqmi=y
CONFIG_PACKAGE_sms-tool=y
CONFIG_PACKAGE_picocom=y
CONFIG_PACKAGE_comgt=y
CONFIG_PACKAGE_comgt-ncm=y
CONFIG_PACKAGE_chat=y
CONFIG_PACKAGE_wwan=y
CONFIG_PACKAGE_luci-proto-qmi=y
CONFIG_PACKAGE_luci-proto-mbim=y
CONFIG_PACKAGE_luci-proto-ncm=y
CONFIG_PACKAGE_luci-proto-wireguard=y
CONFIG_PACKAGE_wireguard-tools=y
CONFIG_PACKAGE_iw=y
CONFIG_PACKAGE_iwinfo=y
CONFIG_PACKAGE_wireless-regdb=y
CONFIG_PACKAGE_coreutils-timeout=y
CONFIG_PACKAGE_coreutils-base64=y
CONFIG_PACKAGE_coreutils-nohup=y
CONFIG_PACKAGE_coreutils-sort=y
CONFIG_PACKAGE_coreutils-stat=y
CONFIG_PACKAGE_flock=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_jq=y
CONFIG_PACKAGE_xxd=y
CONFIG_PACKAGE_socat=y
CONFIG_PACKAGE_etherwake=y
CONFIG_PACKAGE_adb=y
CONFIG_PACKAGE_adb-enablemodem=y
CONFIG_PACKAGE_zoneinfo-core=y
CONFIG_PACKAGE_zoneinfo-asia=y
CONFIG_PACKAGE_autocore=y
CONFIG_PACKAGE_ttyd=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-lua-runtime=y
CONFIG_PACKAGE_ucode-mod-lua=y
CONFIG_PACKAGE_luci-i18n-base-vi=y
CONFIG_PACKAGE_luci-i18n-firewall-vi=y
CONFIG_PACKAGE_luci-i18n-package-manager-vi=y
CONFIG_PACKAGE_luci-i18n-argon-config-vi=y
CONFIG_PACKAGE_luci-i18n-ttyd-vi=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_iperf3=y
CONFIG_PACKAGE_ethtool=y
CONFIG_PACKAGE_tcpdump=y
CONFIG_PACKAGE_nano=y
CONFIG_VERSIONOPT=y
CONFIG_VERSION_DIST="Doanduy"
EOF

# PassWall extra legacy iptables TProxy kmod if available
if grep -q '^CONFIG_PACKAGE_luci-app-passwall=y$' "$CFG"; then
  echo "CONFIG_PACKAGE_kmod-ipt-tproxy=y" >> "$CFG"
fi

# ==============================================================================
# [B] QUALCOMM IPQ (IPQ60xx / IPQ807x) MANDATORY HARDWARE & NSS KMODS
# ==============================================================================
if grep -q '^CONFIG_TARGET_qualcommax=y$' "$CFG"; then
  cat << 'EOF' >> "$CFG"
CONFIG_PACKAGE_kmod-qca-nss-dp=y
CONFIG_PACKAGE_kmod-qca-ssdk=y
CONFIG_PACKAGE_kmod-dsa=y
CONFIG_PACKAGE_kmod-dsa-qca8k=y
CONFIG_PACKAGE_kmod-phy-qca83xx=y
CONFIG_PACKAGE_kmod-phy-realtek=y
CONFIG_PACKAGE_kmod-ath11k=y
CONFIG_PACKAGE_kmod-ath11k-ahb=y
CONFIG_PACKAGE_kmod-ath11k-pci=y
CONFIG_PACKAGE_kmod-spi-gpio=y
CONFIG_PACKAGE_kmod-spi-bitbang=y
CONFIG_PACKAGE_kmod-gpio-nxp-74hc164=y
CONFIG_PACKAGE_kmod-qrtr-smd=y
CONFIG_PACKAGE_kmod-usb-dwc3-qcom=y
CONFIG_PACKAGE_cpufreq=y
CONFIG_PACKAGE_luci-app-cpufreq=y
EOF

  # JDCloud RE-CS-02 (Athena AX6600) pure-C Matrix & RGB LED controller (IPQ60xx only; auto-guards board_name at runtime)
  if grep -q '^CONFIG_TARGET_qualcommax_ipq60xx=y$' "$CFG"; then
    cat << 'EOF' >> "$CFG"
CONFIG_PACKAGE_athena-led=y
CONFIG_PACKAGE_luci-app-athena-led=y
EOF
  fi

  # Full-NSS 12.5 Hardware Offload Suite (qualcomm-nss-25.12)
  if grep -q '^CONFIG_ATH11K_NSS_SUPPORT=y$' "$CFG"; then
    cat << 'EOF' >> "$CFG"
CONFIG_PACKAGE_kmod-qca-nss-drv=y
CONFIG_PACKAGE_kmod-qca-nss-ecm=y
CONFIG_PACKAGE_kmod-qca-nss-crypto=y
CONFIG_PACKAGE_kmod-nss-ifb=y
CONFIG_PACKAGE_sqm-scripts-nss=y
CONFIG_PACKAGE_kmod-qca-nss-drv-pppoe=y
CONFIG_PACKAGE_kmod-qca-nss-drv-bridge-mgr=y
CONFIG_PACKAGE_kmod-qca-nss-drv-vlan-mgr=y
CONFIG_PACKAGE_kmod-qca-nss-drv-qdisc=y
CONFIG_PACKAGE_kmod-qca-nss-drv-igs=y
CONFIG_PACKAGE_kmod-qca-nss-drv-wifi-meshmgr=y
CONFIG_PACKAGE_kmod-qca-nss-drv-gre=y
CONFIG_PACKAGE_kmod-qca-nss-drv-eogremgr=y
CONFIG_PACKAGE_kmod-qca-nss-drv-vxlanmgr=y
CONFIG_PACKAGE_kmod-qca-nss-drv-l2tpv2=y
CONFIG_PACKAGE_kmod-qca-nss-drv-pptp=y
CONFIG_PACKAGE_kmod-qca-nss-drv-tun6rd=y
CONFIG_PACKAGE_kmod-qca-nss-drv-tunipip6=y
CONFIG_PACKAGE_kmod-qca-nss-drv-map-t=y
CONFIG_PACKAGE_kmod-qca-nss-drv-match=y
CONFIG_PACKAGE_kmod-qca-nss-drv-mirror=y
CONFIG_PACKAGE_kmod-qca-nss-drv-lag-mgr=y
CONFIG_PACKAGE_kmod-qca-nss-drv-netlink=y
EOF
  fi
fi

# ==============================================================================
# [C] MEDIATEK FILOGIC (MT7981 / MT7986 / MT7987 / MT7988) MANDATORY KMODS
# ==============================================================================
if grep -q '^CONFIG_TARGET_mediatek_filogic=y$' "$CFG"; then
  cat << 'EOF' >> "$CFG"
CONFIG_PACKAGE_fitblk=y
CONFIG_PACKAGE_eip197-mini-firmware=y
CONFIG_PACKAGE_kmod-crypto-hw-safexcel=y
CONFIG_PACKAGE_kmod-usb-xhci-hcd=y
CONFIG_PACKAGE_kmod-usb-xhci-mtk=y
CONFIG_PACKAGE_kmod-usb-serial-xr_usb_serial_common=y
CONFIG_PACKAGE_kmod-phy-realtek=y
CONFIG_PACKAGE_kmod-phy-motorcomm=y
CONFIG_PACKAGE_kmod-sfp=y
CONFIG_PACKAGE_kmod-leds-ws2812b=y
EOF

  if grep -q '^CONFIG_PACKAGE_kmod-mt_wifi=y$' "$CFG"; then
    # Proprietary mt_wifi + HNAT/WARP (filogic-wed-25.12)
    cat << 'EOF' >> "$CFG"
CONFIG_PACKAGE_kmod-conninfra=y
CONFIG_PACKAGE_kmod-mt_wifi=y
CONFIG_PACKAGE_kmod-warp=y
CONFIG_PACKAGE_kmod-mediatek_hnat=y
EOF
  else
    # Mainline mt76 + PPE/WED + Bridger (master & master-passwall)
    cat << 'EOF' >> "$CFG"
CONFIG_PACKAGE_bridger=y
CONFIG_PACKAGE_kmod-phy-mediatek-2p5g=y
CONFIG_PACKAGE_kmod-phy-mtk-tphy=y
EOF
  fi
fi

# --- Build-time Source Branding Guard (guarantees DOANDUY SSID/Hostname/Dist even after upstream sync) ---
python3 - << 'PYEOF'
import os, re

mac_uc = "package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if os.path.isfile(mac_uc):
    with open(mac_uc, "r", encoding="utf-8") as f:
        s = f.read()
    target_line = """set ${si}.ssid='${band_name == "2g" ? "DOANDUY_2.4G" : (band_name == "5g" ? "DOANDUY_5G" : (band_name == "6g" ? "DOANDUY_6G" : "DOANDUY"))}'"""
    s2 = re.sub(r"set \$\{si\}\.ssid='[^']*'", lambda _: target_line, s)
    if s2 != s:
        with open(mac_uc, "w", encoding="utf-8") as f:
            f.write(s2)

mt_uc = "package/mtk/applications/mtwifi-cfg-ucode/files/lib/wifi/mtwifi.uc"
if os.path.isfile(mt_uc):
    with open(mt_uc, "r", encoding="utf-8") as f:
        s = f.read()
    s2 = (
        s.replace('ssid: "ImmortalWrt-2.4G"', 'ssid: "DOANDUY_2.4G"')
         .replace('ssid: "ImmortalWrt-5G"', 'ssid: "DOANDUY_5G"')
         .replace('ssid: "ImmortalWrt-6G"', 'ssid: "DOANDUY_6G"')
    )
    if s2 != s:
        with open(mt_uc, "w", encoding="utf-8") as f:
            f.write(s2)

cg = "package/base-files/files/bin/config_generate"
if os.path.isfile(cg):
    with open(cg, "r", encoding="utf-8") as f:
        s = f.read()
    s2 = re.sub(r"set system\.@system\[-1\]\.hostname='[^']*'", "set system.@system[-1].hostname='DOANDUY'", s)
    s2 = re.sub(r"set system\.@system\[-1\]\.timezone='GMT0'", "set system.@system[-1].timezone='<+07>-7'", s2)
    s2 = re.sub(r"set system\.@system\[-1\]\.zonename='UTC'", "set system.@system[-1].zonename='Asia/Ho_Chi_Minh'", s2)
    if s2 != s:
        with open(cg, "w", encoding="utf-8") as f:
            f.write(s2)

vmk = "include/version.mk"
if os.path.isfile(vmk):
    with open(vmk, "r", encoding="utf-8") as f:
        s = f.read()
    s2 = re.sub(
        r"VERSION_DIST:=\$\(if \$\(VERSION_DIST\),\$\(VERSION_DIST\),[^)]+\)",
        "VERSION_DIST:=$(if $(VERSION_DIST),$(VERSION_DIST),Doanduy)",
        s,
    )
    if s2 != s:
        with open(vmk, "w", encoding="utf-8") as f:
            f.write(s2)
PYEOF

# --- [D] Physical Flash Capacity Guard: Auto-skip tiny-flash profiles that cannot physically fit the selected ROM tier ---
python3 - "$CFG" << 'PYEOF'
import glob, os, re, sys

cfg_path = sys.argv[1]
if os.path.isfile(cfg_path):
    with open(cfg_path, "r", encoding="utf-8", errors="replace") as f:
        cfg_txt = f.read()
    has_pw = bool(re.search(r"^CONFIG_PACKAGE_luci-app-passwall2?=y$", cfg_txt, re.M))
    min_kb = 60416 if has_pw else 16384  # 59 MB min for Full PassWall (Xray+SingBox); 16 MB min for NoPassWall

    def parse_kb(raw: str):
        s = raw.strip().lower()
        m = re.match(r"^(\d+)\s*([km]?)$", s)
        if not m:
            return None
        v, u = int(m.group(1)), m.group(2)
        return v * 1024 if u == "m" else (v if u == "k" else v // 1024)

    blocks = {}
    for mk in sorted(glob.glob("target/linux/*/image/*.mk")):
        with open(mk, "r", encoding="utf-8", errors="replace") as mf:
            txt = mf.read()
        for m in re.finditer(r"define Device/([^\s\n]+)\n(.*?)\nendef", txt, re.S):
            blocks[m.group(1)] = m.group(2)

    too_small = set()
    for dev, blk in blocks.items():
        merged = blk
        for parent in re.findall(r"\$\(call Device/([^\)]+)\)", blk):
            if parent in blocks:
                merged = blocks[parent] + "\n" + merged
        msz = re.findall(r"^\s*IMAGE_SIZE\s*:=\s*([^\n]+)", merged, re.M)
        if msz:
            kb = parse_kb(msz[-1])
            if kb is not None and kb < min_kb:
                too_small.add(dev)

    if too_small:
        dropped = []
        out_lines = []
        for ln in cfg_txt.splitlines():
            m = re.match(r"^(CONFIG_TARGET_DEVICE_[^=]+_DEVICE_([^=]+))=y$", ln)
            if m and m.group(2) in too_small:
                dropped.append(m.group(2))
                out_lines.append(f"# {m.group(1)} is not set")
                continue
            out_lines.append(ln)
        if dropped:
            with open(cfg_path, "w", encoding="utf-8", newline="\n") as f:
                f.write("\n".join(out_lines) + "\n")
            tier = "PassWall (>=59MB)" if has_pw else "NoPassWall (>=16MB)"
            print(f">> [FLASH GUARD] Auto-skipped {len(dropped)} small-flash profile(s) for {tier}: {', '.join(sorted(dropped))}")
PYEOF
