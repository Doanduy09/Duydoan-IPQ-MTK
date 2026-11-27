#!/bin/sh
# Unified Full Kmod, Firmware & Userspace Baseline (audited against live SDMC NR3053 r89 & 11 reference devices)
# Safe across Qualcomm IPQ60xx/IPQ807x & MediaTek Filogic (PassWall & No-PassWall, Kernel 6.12 & 6.18)
set -e

CFG="${1:-.config}"
[ -f "$CFG" ] || exit 0

cat << 'EOF' >> "$CFG"
# --- 1. USB Host Controllers, Hub & Modeswitch ---
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-usb-ehci=y
CONFIG_PACKAGE_kmod-usb-ohci=y
CONFIG_PACKAGE_kmod-usb-uhci=y
CONFIG_PACKAGE_kmod-usb-dwc2=y
CONFIG_PACKAGE_kmod-usb-dwc3=y
CONFIG_PACKAGE_kmod-usb-roles=y
CONFIG_PACKAGE_usb-modeswitch=y
CONFIG_PACKAGE_usbutils=y

# --- 1b. PCIe 5G Modem (MHI Bus/Net/AT-QMI-Ctrl/MBIM, MediaTek T7xx, Qualcomm QRTR & RMNET) ---
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

# --- 2. USB Modem 4G/5G, USB-to-LAN & iPhone/Android Tethering ---
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
CONFIG_PACKAGE_kmod-phy-aquantia=y

# --- 3. USB Serial / AT / Debug ---
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

# --- 4. USB Storage, Auto-Mount & Filesystems (/overlay F2FS + External Drives) ---
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_kmod-usb-storage-extras=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-f2fs=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_e2fsprogs=y
CONFIG_PACKAGE_mkf2fs=y
CONFIG_PACKAGE_f2fsck=y

# --- 5. Thermal, Crypto & Networking / VPN / TProxy Kmods ---
CONFIG_PACKAGE_kmod-thermal=y
CONFIG_PACKAGE_kmod-hwmon-core=y
CONFIG_PACKAGE_kmod-i2c-core=y
CONFIG_PACKAGE_kmod-crypto-aead=y
CONFIG_PACKAGE_kmod-crypto-authenc=y
CONFIG_PACKAGE_kmod-crypto-ccm=y
CONFIG_PACKAGE_kmod-crypto-cmac=y
CONFIG_PACKAGE_kmod-crypto-ctr=y
CONFIG_PACKAGE_kmod-crypto-des=y
CONFIG_PACKAGE_kmod-crypto-ecb=y
CONFIG_PACKAGE_kmod-crypto-gcm=y
CONFIG_PACKAGE_kmod-crypto-gf128=y
CONFIG_PACKAGE_kmod-crypto-ghash=y
CONFIG_PACKAGE_kmod-crypto-hmac=y
CONFIG_PACKAGE_kmod-crypto-manager=y
CONFIG_PACKAGE_kmod-crypto-md5=y
CONFIG_PACKAGE_kmod-crypto-null=y
CONFIG_PACKAGE_kmod-crypto-rng=y
CONFIG_PACKAGE_kmod-crypto-seqiv=y
CONFIG_PACKAGE_kmod-crypto-sha512=y
CONFIG_PACKAGE_kmod-crypto-user=y
CONFIG_PACKAGE_kmod-tcp-bbr=y
CONFIG_PACKAGE_kmod-nf-conntrack6=y
CONFIG_PACKAGE_kmod-nf-nathelper=y
CONFIG_PACKAGE_kmod-nf-nathelper-extra=y
CONFIG_PACKAGE_kmod-nft-fullcone=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-ipt-ipopt=y
CONFIG_PACKAGE_iptables-nft=y
CONFIG_PACKAGE_ip6tables-nft=y
CONFIG_PACKAGE_iptables-mod-ipopt=y
CONFIG_PACKAGE_kmod-sched-cake=y
CONFIG_PACKAGE_kmod-wireguard=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_kmod-veth=y
CONFIG_PACKAGE_kmod-bonding=y
CONFIG_PACKAGE_kmod-macvlan=y
CONFIG_PACKAGE_kmod-usb-ledtrig-usbport=y
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppoe=y
CONFIG_PACKAGE_kmod-mppe=y

# --- 6. Fast 5G Dialers (quectel-cm + uqmi + umbim + atinout), Auto-Mesh Wi-Fi Tools & LuCI VI ---
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

# Qualcomm IPQ60xx / IPQ807x SMD IPC Router & DWC3-QCOM USB3 Glue
if grep -q '^CONFIG_TARGET_qualcommax=y$' "$CFG"; then
  cat << 'EOF' >> "$CFG"
CONFIG_PACKAGE_kmod-qrtr-smd=y
CONFIG_PACKAGE_kmod-usb-dwc3-qcom=y
EOF
fi

# MediaTek Filogic hardware EIP-97 crypto engine, xHCI USB3 & Exar USB-serial driver
if grep -q '^CONFIG_TARGET_mediatek_filogic=y$' "$CFG"; then
  cat << 'EOF' >> "$CFG"
CONFIG_PACKAGE_eip197-mini-firmware=y
CONFIG_PACKAGE_kmod-crypto-hw-safexcel=y
CONFIG_PACKAGE_kmod-usb-xhci-hcd=y
CONFIG_PACKAGE_kmod-usb-xhci-mtk=y
CONFIG_PACKAGE_kmod-usb-serial-xr_usb_serial_common=y
EOF
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
