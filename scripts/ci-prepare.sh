#!/usr/bin/env bash
# [VERIFIED-GOLDEN: ci-prepare-v4-passwall2-lean-vi-and-mt3053-guard | 2026-11-27 | DO NOT MODIFY UNLESS TARGETED]
# Unified Pre-Build Preparation, 5G Binary Embedding & NAND Partition Gate (Duydoan-IPQ-MTK)
set -euo pipefail

echo "=========================================================="
echo ">> [1/4] Embedding DoanDuy Modem Suite, atinout & quectel-cm-5g..."
echo "=========================================================="
# 1. Embed DoanDuy Modem, Auto-Mesh & SmartHome Suite (v2.6.4+) directly into package/
rm -rf package/luci-app-doanduy-modem /tmp/doanduy-modem
git clone --depth 1 https://github.com/Doanduy09/luci-app-doanduy-modem.git /tmp/doanduy-modem
cp -r /tmp/doanduy-modem/luci-app-doanduy-modem package/
rm -rf /tmp/doanduy-modem

# 2. Ensure atinout exists in package/utils/atinout across all branches (master & 25.12)
if [ ! -f package/utils/atinout/Makefile ]; then
  mkdir -p package/utils/atinout
  cat << 'AT_EOF' > package/utils/atinout/Makefile
include $(TOPDIR)/rules.mk

PKG_NAME:=atinout
PKG_VERSION:=0.9.1
PKG_RELEASE:=1
PKG_LICENSE:=GPLv2
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/beralt/atinout.git
PKG_SOURCE_VERSION:=4013e8db4cd140c1df24bb90f929efeb9b61b238
PKG_MIRROR_HASH:=skip
PKG_SOURCE_SUBDIR:=$(PKG_NAME)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Telephony
	TITLE:=Send AT commands to a modem
endef

CONFIGURE_VARS += \
  CC="$(TARGET_CC)" \
  CFLAGS="$(TARGET_CFLAGS) -Wall -DVERSION=\"\\\"$(PKG_VERSION)\\\"\"" \
  LDFLAGS="$(TARGET_LDFLAGS)"

define Build/Configure
	true
endef

define Build/Compile
	$(CONFIGURE_VARS) $(MAKE) -C $(PKG_BUILD_DIR) all
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_NAME) $(1)/usr/bin/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
AT_EOF
fi

# 3. Embed standalone quectel-cm-5g (from FUjr/QModem) so /usr/bin/quectel-cm & /usr/bin/quectel-CM-M are built into every ROM
rm -rf package/utils/quectel-cm-5g /tmp/qmodem-cm
git clone --depth 1 https://github.com/FUjr/QModem.git /tmp/qmodem-cm
if [ -d /tmp/qmodem-cm/application/quectel_CM_5G_M/src ]; then
  mkdir -p package/utils/quectel-cm-5g
  cp -r /tmp/qmodem-cm/application/quectel_CM_5G_M/src package/utils/quectel-cm-5g/
  [ -d /tmp/qmodem-cm/application/quectel_CM_5G_M/files ] && cp -r /tmp/qmodem-cm/application/quectel_CM_5G_M/files package/utils/quectel-cm-5g/
  # Strip -Werror for GCC 13/14 Kernel 6.18 compatibility
  sed -i 's/-Werror //g; s/-Werror$//g' package/utils/quectel-cm-5g/src/Makefile
  cat << 'QCM_EOF' > package/utils/quectel-cm-5g/Makefile
include $(TOPDIR)/rules.mk

PKG_NAME:=quectel-cm-5g
PKG_VERSION:=1.6.8
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/quectel-cm-5g
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=WWAN
  TITLE:=High-speed QMI/MBIM 5G Connection Manager (quectel-cm & quectel-CM-M)
  DEPENDS:=+libjson-c +libpthread
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		$(TARGET_CONFIGURE_OPTS) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wno-error"
endef

define Package/quectel-cm-5g/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/share/qmodem
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/quectel-CM $(1)/usr/bin/quectel-cm
	ln -sf quectel-cm $(1)/usr/bin/quectel-CM-M
	[ -f $(PKG_BUILD_DIR)/quectel-qmi-proxy ] && $(INSTALL_BIN) $(PKG_BUILD_DIR)/quectel-qmi-proxy $(1)/usr/bin/quectel-qmi-proxy || true
	[ -f $(PKG_BUILD_DIR)/quectel-mbim-proxy ] && $(INSTALL_BIN) $(PKG_BUILD_DIR)/quectel-mbim-proxy $(1)/usr/bin/quectel-mbim-proxy || true
	[ -f ./files/apns.json ] && $(INSTALL_DATA) ./files/apns.json $(1)/usr/share/qmodem/apns.json || true
endef

$(eval $(call BuildPackage,quectel-cm-5g))
QCM_EOF
fi
rm -rf /tmp/qmodem-cm

# Purge any legacy /etc/init.d/all or all.enc (replaced 100% by duydoan5g dialer + auto_mesh)
rm -f package/base-files/files/etc/init.d/all package/base-files/files/etc/init.d/all.enc \
      files/etc/init.d/all files/etc/init.d/all.enc 2>/dev/null || true

echo "=========================================================="
echo ">> [2/4] Enforcing MediaTek sdmc_mt3053 NAND Partition, factory.ubi & FIT Image Guard..."
echo "=========================================================="
python3 - << 'PYEOF'
import os, re, sys

filogic_mk = "target/linux/mediatek/image/filogic.mk"
filogic_ext_mk = "target/linux/mediatek/image/filogic-ext.mk"
has_sdmc_mt3053 = False
if os.path.isfile(filogic_mk):
    with open(filogic_mk, "r", encoding="utf-8") as f:
        mk_txt = f.read()
    has_sdmc_mt3053 = bool(re.search(r"^define Device/sdmc_mt3053\b", mk_txt, re.M))

    # B1. Enforce guarded factory.ubi on Device/sdmc_mt3053 in filogic.mk (only on MediaTek branches where sdmc_mt3053 exists)
    m_dev = re.search(r"(define Device/sdmc_mt3053\b.*?\nendef)", mk_txt, re.S)
    orig_mk = mk_txt
    if m_dev:
        blk = m_dev.group(1)
        new_blk = blk
        ubi_snippet = (
            "ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)\n"
            "  ARTIFACTS := factory.ubi\n"
            "  ARTIFACT/factory.ubi := append-image-stage initramfs-kernel.bin | ubinize-kernel\n"
            "endif\n"
        )
        if "ARTIFACT/factory.ubi" not in blk:
            new_blk = blk.replace("endef", ubi_snippet + "endef")
        elif "CONFIG_TARGET_ROOTFS_INITRAMFS" not in blk:
            new_blk = re.sub(
                r"[ \t]*ARTIFACTS\s*:=\s*factory\.ubi\s*\n[ \t]*ARTIFACT/factory\.ubi\s*:=\s*[^\n]+\n",
                ubi_snippet,
                blk,
            )
        if new_blk != blk:
            mk_txt = mk_txt[:m_dev.start()] + new_blk + mk_txt[m_dev.end():]
            print("  [FIXED] Enforced guarded factory.ubi recipe in Device/sdmc_mt3053.")
        print("  [PASS] Device/sdmc_mt3053 factory.ubi recipe verified.")

    # B2. If filogic-ext.mk already defines Device/viettel_nr3053, remove duplicate Device/viettel_nr3053 from filogic.mk
    ext_has_nr3053 = False
    if os.path.isfile(filogic_ext_mk):
        with open(filogic_ext_mk, "r", encoding="utf-8") as ef:
            ext_has_nr3053 = bool(re.search(r"^define Device/viettel_nr3053\b", ef.read(), re.M))
    if ext_has_nr3053:
        mk_txt2 = re.sub(
            r"\n*define Device/viettel_nr3053\b.*?\nendef\s*\nTARGET_DEVICES \+= viettel_nr3053\s*\n",
            "\n",
            mk_txt,
            flags=re.S,
        )
        if mk_txt2 != mk_txt:
            mk_txt = mk_txt2
            print("  [FIXED] Removed duplicate Device/viettel_nr3053 from filogic.mk (canonical in filogic-ext.mk).")

    # B3. Ensure ubootmod FIT devices (viettel_nr3053 & wirelesstag_zx7981pd-ubootmod) do NOT emit sysupgrade-tar sysupgrade.bin
    for fit_dev in ("viettel_nr3053", "wirelesstag_zx7981pd-ubootmod"):
        m_fit = re.search(rf"(define Device/{re.escape(fit_dev)}\b.*?\nendef)", mk_txt, re.S)
        if m_fit:
            fblk = m_fit.group(1)
            fblk_new = re.sub(r"IMAGES\s*:=\s*sysupgrade\.itb\s+sysupgrade\.bin", "IMAGES := sysupgrade.itb", fblk)
            fblk_new = re.sub(r"[ \t]*IMAGE/sysupgrade\.bin\s*:=\s*sysupgrade-tar[^\n]*\n", "", fblk_new)
            if fblk_new != fblk:
                mk_txt = mk_txt[:m_fit.start()] + fblk_new + mk_txt[m_fit.end():]
                print(f"  [FIXED] Cleaned FIT-only IMAGES := sysupgrade.itb on Device/{fit_dev}.")

    # B4. Guard upstream unguarded initramfs ARTIFACTS (asus_rt-ax52, asus_rt-ax57m, openwrt_one) when CONFIG_TARGET_ROOTFS_INITRAMFS is disabled (PassWall builds)
    for ax_dev in ("asus_rt-ax52", "asus_rt-ax57m"):
        m_ax = re.search(rf"(define Device/{re.escape(ax_dev)}\b.*?\nendef)", mk_txt, re.S)
        if m_ax and "CONFIG_TARGET_ROOTFS_INITRAMFS" not in m_ax.group(1):
            ablk = m_ax.group(1)
            ablk_new = re.sub(
                r"(ifeq \(\$\(IB\),\)\n)([ \t]*ARTIFACTS\s*:=\s*initramfs\.trx\n.*?\n)(endif)",
                r"\1ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)\n\2endif\n\3",
                ablk,
                flags=re.S,
            )
            if ablk_new != ablk:
                mk_txt = mk_txt[:m_ax.start()] + ablk_new + mk_txt[m_ax.end():]
                print(f"  [FIXED] Guarded ARTIFACTS := initramfs.trx with CONFIG_TARGET_ROOTFS_INITRAMFS on Device/{ax_dev}.")

    m_ow1 = re.search(r"(define Device/openwrt_one\b.*?\nendef)", mk_txt, re.S)
    if m_ow1 and "CONFIG_TARGET_ROOTFS_INITRAMFS" not in m_ow1.group(1):
        oblk = m_ow1.group(1)
        oblk_new = re.sub(
            r"([ \t]*ARTIFACTS\s*:=\s*\\\n(?:[ \t]*[^\n]+\\\n)*[ \t]*factory\.ubi[^\n]*\n)",
            r"ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)\n\1endif\n",
            oblk,
        )
        if oblk_new != oblk:
            mk_txt = mk_txt[:m_ow1.start()] + oblk_new + mk_txt[m_ow1.end():]
            print("  [FIXED] Guarded initramfs-dependent ARTIFACTS with CONFIG_TARGET_ROOTFS_INITRAMFS on Device/openwrt_one.")

    # B5. Move vendor post-packers (iptime-crc32, zyimage, zyxel-nwa-fit-filogic, netgear-encrypted-factory) BEFORE check-size
    # so Build/check-size's 'rm -f $@' on oversized images never crashes a downstream packer with 'No such file or directory'
    mk_fixed_pipe = re.sub(
        r"\|\s*(check-size(?:\s+\$\$+\(IMAGE_SIZE\))?)\s*\|\s*((?:iptime-crc32|zyimage|zyxel-nwa-fit-filogic|netgear-encrypted-factory)[^\n|\\]*)",
        lambda m: f"| {m.group(2).strip()} | {m.group(1).strip()}",
        mk_txt,
    )
    if mk_fixed_pipe != mk_txt:
        mk_txt = mk_fixed_pipe
        print("  [FIXED] Reordered vendor post-packers (iptime-crc32/zyimage/zyxel/netgear) before check-size in filogic.mk.")

    if mk_txt != orig_mk:
        with open(filogic_mk, "w", encoding="utf-8", newline="\n") as f:
            f.write(mk_txt)

# A. Enforce sdmc,mt3053 in all 3 NAND upgrade hooks in platform.sh ONLY when Device/sdmc_mt3053 is part of this branch
plat_sh = "target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh"
if has_sdmc_mt3053 and os.path.isfile(plat_sh):
    with open(plat_sh, "r", encoding="utf-8") as f:
        s = f.read()
    orig = s
    # Hook 1: xiaomi_initial_setup fw_setenv mtdparts
    m_mtd = re.search(r"([ \t]*xiaomi,mi-router-ax3000t\|\\\n(?:.*\n){0,4}?[ \t]*fw_setenv mtdparts)", s)
    if m_mtd:
        window_start = max(0, m_mtd.start() - 120)
        if "sdmc,mt3053" not in s[window_start:m_mtd.end()]:
            s = s[:m_mtd.start()] + "\tsdmc,mt3053|\\\n" + s[m_mtd.start():]
            print("  [FIXED] Restored sdmc,mt3053 -> fw_setenv mtdparts in platform.sh")
    # Hook 2: platform_do_upgrade CI_KERN_UBIPART
    m_upg = re.search(r"([ \t]*xiaomi,mi-router-ax3000t\|\\\n(?:.*\n){0,4}?[ \t]*CI_KERN_UBIPART=)", s)
    if m_upg:
        window_start = max(0, m_upg.start() - 120)
        if "sdmc,mt3053" not in s[window_start:m_upg.end()]:
            s = s[:m_upg.start()] + "\tsdmc,mt3053|\\\n" + s[m_upg.start():]
            print("  [FIXED] Restored sdmc,mt3053 -> CI_KERN_UBIPART=ubi_kernel in platform.sh")
    # Hook 3: platform_pre_upgrade xiaomi_initial_setup
    m_pre = re.search(r"([ \t]*xiaomi,mi-router-ax3000t\|\\\n(?:.*\n){0,4}?[ \t]*xiaomi_initial_setup)", s)
    if m_pre:
        window_start = max(0, m_pre.start() - 120)
        if "sdmc,mt3053" not in s[window_start:m_pre.end()]:
            s = s[:m_pre.start()] + "\tsdmc,mt3053|\\\n" + s[m_pre.start():]
            print("  [FIXED] Restored sdmc,mt3053 -> xiaomi_initial_setup in platform.sh")
    if s != orig:
        with open(plat_sh, "w", encoding="utf-8", newline="\n") as f:
            f.write(s)
    if s.count("sdmc,mt3053") < 3:
        print(f"[FATAL] sdmc,mt3053 appears only {s.count('sdmc,mt3053')} time(s) in {plat_sh} (expected >= 3)!", file=sys.stderr)
        sys.exit(1)
    print(f"  [PASS] {plat_sh}: sdmc,mt3053 verified in all 3 NAND upgrade hooks.")
else:
    print("  [SKIP] Target branch does not build MediaTek sdmc_mt3053 (Qualcomm-only branch).")
PYEOF

echo "=========================================================="
echo ">> [3/4] Updating & Installing OpenWrt Feeds..."
echo "=========================================================="
./scripts/feeds update -a || ./scripts/feeds update -f -a || true
if [ ! -s feeds/packages.index ] || [ ! -s feeds/luci.index ]; then
  echo "[FATAL] Core OpenWrt feeds (packages/luci) failed to update!" >&2
  exit 1
fi

# Fix +wget-any virtual dependency on opkg branches (where USE_APK depends on BROKEN)
if [ -f config/Config-build.in ] && awk '/config USE_APK/,/comment /' config/Config-build.in | grep -q 'depends on BROKEN'; then
  for fd in feeds/luci feeds/packages feeds/all; do
    [ -d "$fd" ] && find "$fd" -type f \( -name 'Makefile' -o -name '*.mk' \) -exec sed -i 's/+wget-any/+wget-ssl/g' {} + || true
  done
fi

# Prioritize luci-app-doanduy-modem ownership of modem_ctrl & 11_modem.js
rm -f \
  feeds/qmodem/application/qmodem/files/usr/libexec/rpcd/modem_ctrl \
  feeds/qmodem/luci/luci-app-qmodem/htdocs/luci-static/resources/view/status/include/11_modem.js \
  feeds/qmodem/luci/luci-app-qmodem-next/htdocs/luci-static/resources/view/status/include/11_modem.js \
  feeds/all/qmodem/files/usr/libexec/rpcd/modem_ctrl \
  feeds/all/luci-app-qmodem/htdocs/luci-static/resources/view/status/include/11_modem.js 2>/dev/null || true

if [ -f feeds/packages/net/haproxy/Makefile ]; then
  sed -i '/USE_QUIC=1/d; /USE_QUIC_OPENSSL_COMPAT=1/d' feeds/packages/net/haproxy/Makefile
fi

# Configure PassWall 2 (Lean Single-Core Sing-Box + Pure Nftables + 100% Vietnamese UI) before feed indexing
if [ -d feeds/passwall2/luci-app-passwall2 ]; then
  echo ">> [PassWall 2] Injecting 100% Vietnamese translation (luci-i18n-passwall2-vi) & Sing-Box lean defaults..."
  if [ -f .github/assets/passwall2.vi.po ]; then
    mkdir -p feeds/passwall2/luci-app-passwall2/po/vi
    cp -f .github/assets/passwall2.vi.po feeds/passwall2/luci-app-passwall2/po/vi/passwall2.po
  fi
  python3 - << 'PW2_EOF'
import os, re

base = "feeds/passwall2/luci-app-passwall2"

# 1. Lock Kconfig defaults to Sing-Box only & disable redundant cores/plugins by default
mk = os.path.join(base, "Makefile")
if os.path.isfile(mk):
    with open(mk, "r", encoding="utf-8") as f:
        s = f.read()
    s = re.sub(r"default PACKAGE_\$\(PKG_NAME\)_Basic_Core_All[^\n]*", "default PACKAGE_$(PKG_NAME)_Basic_Core_SingBox", s)
    s = s.replace("default PACKAGE_$(PKG_NAME)_Basic_Core_Xray", "default PACKAGE_$(PKG_NAME)_Basic_Core_SingBox")
    for opt in ("INCLUDE_Haproxy", "INCLUDE_Shadowsocks_Rust_Client", "INCLUDE_ShadowsocksR_Libev_Client", "INCLUDE_Simple_Obfs", "INCLUDE_V2ray_Plugin"):
        s = re.sub(rf"(config PACKAGE_\$\(PKG_NAME\)_{opt}\n(?:[^\n]*\n)*?\t)default y[^\n]*", r"\1default n", s)
    with open(mk, "w", encoding="utf-8", newline="\n") as f:
        f.write(s)

# 2. Switch default examplenode & rulenode from 'Xray' to 'sing-box' so Sing-Box-only builds work out of the box
def_cfg = os.path.join(base, "root/usr/share/passwall2/0_default_config")
if os.path.isfile(def_cfg):
    with open(def_cfg, "r", encoding="utf-8") as f:
        s = f.read()
    s = s.replace("\toption type 'Xray'", "\toption type 'sing-box'")
    s = s.replace("\toption transport 'raw'", "\toption transport 'tcp'")
    with open(def_cfg, "w", encoding="utf-8", newline="\n") as f:
        f.write(s)

# 3. Use global Cloudflare DoH (1.1.1.1) instead of China AliDNS (223.5.5.5) for Sing-Box ECH lookups
sb_lua = os.path.join(base, "luasrc/passwall2/util_sing-box.lua")
if os.path.isfile(sb_lua):
    with open(sb_lua, "r", encoding="utf-8") as f:
        s = f.read()
    s = s.replace('server = "223.5.5.5"', 'server = "1.1.1.1"')
    with open(sb_lua, "w", encoding="utf-8", newline="\n") as f:
        f.write(s)

# 4. Fix APK 0-byte .list false warning for built-in/kmod nftables dependencies on ImmortalWrt 25.12 & SNAPSHOT
app_sh = os.path.join(base, "root/usr/share/passwall2/app.sh")
if os.path.isfile(app_sh):
    with open(app_sh, "r", encoding="utf-8") as f:
        s = f.read()
    s = s.replace(
        'if [ ! -s "${file_path}/${pkg}${file_ext}" ]; then',
        'if [ ! -e "${file_path}/${pkg}${file_ext}" ] && ! grep -qx "P:${pkg}" /lib/apk/db/installed 2>/dev/null; then',
    )
    with open(app_sh, "w", encoding="utf-8", newline="\n") as f:
        f.write(s)
PW2_EOF
  ./scripts/feeds update -i passwall2
fi

# Prevent MULTI_PROFILE MediaTek image assembly failures when ubootmod devices declare preloader/fip ARTIFACTS without BL2 packages enabled
python3 - << 'PYEOF'
import os, re
for mk in ("target/linux/mediatek/image/filogic.mk", "target/linux/mediatek/image/filogic-ext.mk"):
    if not os.path.isfile(mk):
        continue
    with open(mk, "r", encoding="utf-8") as f:
        lines = f.readlines()
    out = []
    skip_cont = False
    for ln in lines:
        if skip_cont:
            skip_cont = ln.rstrip("\r\n").endswith("\\")
            continue
        if re.match(r"^\s*(ARTIFACTS\s*:=\s*.*preloader\.bin|ARTIFACT/(preloader\.bin|bl31-uboot\.fip)\s*:=)", ln):
            skip_cont = ln.rstrip("\r\n").endswith("\\")
            continue
        out.append(ln)
    with open(mk, "w", encoding="utf-8", newline="\n") as f:
        f.writelines(out)
PYEOF

./scripts/feeds install -a

for f in \
  feeds/all/fibocom_QMI_WWAN/src/qmi_wwan_f.c \
  feeds/qmodem/driver/fibocom_QMI_WWAN/src/qmi_wwan_f.c; do
  if [ -f "$f" ]; then
    sed -i 's/^int qma_setting_store/static int qma_setting_store/g' "$f"
    sed -i 's/int qma_setting_store/static int qma_setting_store/g' "$f"
    sed -i 's/static static int qma_setting_store/static int qma_setting_store/g' "$f"
  fi
done

for f in \
  feeds/all/simcom_QMI_WWAN/src/qmi_wwan_s.c \
  feeds/qmodem/driver/simcom_QMI_WWAN/src/qmi_wwan_s.c; do
  if [ -f "$f" ]; then
    sed -i 's/^struct sk_buff \*qmi_wwan_tx_fixup/static struct sk_buff \*qmi_wwan_tx_fixup/g' "$f"
    sed -i 's/struct sk_buff \*qmi_wwan_tx_fixup/static struct sk_buff \*qmi_wwan_tx_fixup/g' "$f"
    sed -i 's/static static struct sk_buff \*qmi_wwan_tx_fixup/static struct sk_buff \*qmi_wwan_tx_fixup/g' "$f"
  fi
done

for f in \
  feeds/nss_packages/qca-nss-ecm/Makefile \
  package/feeds/nss_packages/qca-nss-ecm/Makefile; do
  if [ -f "$f" ]; then
    sed -i 's/ECM_INTERFACE_RAWIP_ENABLE=y/ECM_INTERFACE_RAWIP_ENABLE=n/g' "$f"
  fi
done

echo "=========================================================="
echo ">> [4/4] Pre-flight Shell Syntax Gate (Fail-Fast)..."
echo "=========================================================="
for d in files/etc/init.d files/etc/uci-defaults files/usr/bin files/etc/hotplug.d \
         package/base-files/files/etc/uci-defaults package/base-files/files/usr/bin \
         target/linux/mediatek/filogic/base-files/lib/upgrade; do
  [ -d "$d" ] || continue
  find "$d" -type f -exec chmod +x {} + 2>/dev/null || true
  for sf in "$d"/*; do
    [ -f "$sf" ] || continue
    case "$sf" in *.enc|*.json|*.conf) continue ;; esac
    if head -n 1 "$sf" | grep -qE '^#!/(usr/)?bin/(ba)?sh'; then
      sh -n "$sf"
    elif [ "${d%uci-defaults}" != "$d" ] || [ "${sf%platform.sh}" != "$sf" ]; then
      sh -n "$sf"
    fi
  done
done
echo "   [PASS] All uci-defaults, upgrade platform.sh & custom shell scripts passed sh -n gate"
# [/VERIFIED-GOLDEN]
