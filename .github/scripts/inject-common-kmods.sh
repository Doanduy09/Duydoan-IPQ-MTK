#!/bin/sh
# Unified Common kmod Baseline (derived from 11 reference devices in Desktop\Rom wifi)
# Safe across Qualcomm IPQ60xx/IPQ807x & MediaTek Filogic (PassWall & No-PassWall)
set -e

CFG="${1:-.config}"
[ -f "$CFG" ] || exit 0

cat << 'EOF' >> "$CFG"
# --- Common USB Modem 4G/5G, USB-to-LAN & iPhone Tethering ---
CONFIG_PACKAGE_kmod-usb-net-qmi-wwan=y
CONFIG_PACKAGE_kmod-usb-net-qmi-wwan-fibocom=y
CONFIG_PACKAGE_kmod-usb-net-qmi-wwan-quectel=y
CONFIG_PACKAGE_kmod-usb-net-cdc-mbim=y
CONFIG_PACKAGE_kmod-usb-net-cdc-ncm=y
CONFIG_PACKAGE_kmod-usb-net-huawei-cdc-ncm=y
CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y
CONFIG_PACKAGE_kmod-usb-net-rndis=y
CONFIG_PACKAGE_kmod-usb-net-sierrawireless=y
CONFIG_PACKAGE_kmod-usb-net-ipheth=y
CONFIG_PACKAGE_kmod-usb-net-rtl8152=y
CONFIG_PACKAGE_kmod-usb-net-rtl8150=y
CONFIG_PACKAGE_kmod-usb-net-asix=y
CONFIG_PACKAGE_kmod-usb-net-asix-ax88179=y
CONFIG_PACKAGE_kmod-usb-net-aqc111=y

# --- Common USB Serial / AT / Debug ---
CONFIG_PACKAGE_kmod-usb-serial-option=y
CONFIG_PACKAGE_kmod-usb-serial-wwan=y
CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y
CONFIG_PACKAGE_kmod-usb-serial-sierrawireless=y
CONFIG_PACKAGE_kmod-usb-serial-cp210x=y
CONFIG_PACKAGE_kmod-usb-serial-ch341=y
CONFIG_PACKAGE_kmod-usb-serial-ftdi=y
CONFIG_PACKAGE_kmod-usb-serial-pl2303=y
CONFIG_PACKAGE_kmod-usb-acm=y
CONFIG_PACKAGE_kmod-usb-wdm=y

# --- Common USB Storage & Filesystems (/overlay F2FS + external drives) ---
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_kmod-usb-storage-extras=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-f2fs=y
CONFIG_PACKAGE_mkf2fs=y
CONFIG_PACKAGE_f2fsck=y

# --- Common Networking, VPN, PPP & LED ---
CONFIG_PACKAGE_kmod-tcp-bbr=y
CONFIG_PACKAGE_kmod-nft-fullcone=y
CONFIG_PACKAGE_kmod-wireguard=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_kmod-macvlan=y
CONFIG_PACKAGE_kmod-usb-ledtrig-usbport=y
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppoe=y
CONFIG_PACKAGE_kmod-mppe=y

# --- Common 5G Dialer Userspace & Vietnamese LuCI & Doanduy Firmware Naming ---
CONFIG_PACKAGE_umbim=y
CONFIG_PACKAGE_uqmi=y
CONFIG_PACKAGE_sms-tool=y
CONFIG_PACKAGE_luci-i18n-base-vi=y
CONFIG_PACKAGE_luci-i18n-firewall-vi=y
CONFIG_VERSIONOPT=y
CONFIG_VERSION_DIST="Doanduy"
EOF

# PassWall extra TProxy/Socket kmods (only when PassWall is enabled)
if grep -q '^CONFIG_PACKAGE_luci-app-passwall=y$' "$CFG"; then
  cat << 'EOF' >> "$CFG"
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-ipt-tproxy=y
EOF
fi

# MediaTek Filogic USB-serial Exar driver (used on FZS/ZX7981 CPE)
if grep -q '^CONFIG_TARGET_mediatek_filogic=y$' "$CFG"; then
  echo "CONFIG_PACKAGE_kmod-usb-serial-xr_usb_serial_common=y" >> "$CFG"
fi
