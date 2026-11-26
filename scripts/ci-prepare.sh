#!/usr/bin/env bash
# [VERIFIED-GOLDEN: ci-prepare-no-all-enc-v2 | 2026-11-26 | DO NOT MODIFY UNLESS TARGETED]
# Unified Pre-Build Preparation & Security/Syntax Gate (Duydoan-IPQ-MTK)
set -euo pipefail

echo "=========================================================="
echo ">> [1/3] Updating & Installing OpenWrt Feeds..."
echo "=========================================================="
# Embed DoanDuy Modem & SmartHome Suite (v2.5.0+) directly into package/
rm -rf package/luci-app-doanduy-modem /tmp/doanduy-modem
git clone --depth 1 https://github.com/Doanduy09/luci-app-doanduy-modem.git /tmp/doanduy-modem
cp -r /tmp/doanduy-modem/luci-app-doanduy-modem package/
rm -rf /tmp/doanduy-modem

# Purge any legacy /etc/init.d/all or all.enc (replaced 100% by duydoan5g dialer)
rm -f package/base-files/files/etc/init.d/all package/base-files/files/etc/init.d/all.enc \
      files/etc/init.d/all files/etc/init.d/all.enc 2>/dev/null || true

./scripts/feeds update -a || ./scripts/feeds update -a

# Fix +wget-any virtual dependency on opkg branches (where USE_APK depends on BROKEN)
if [ -f config/Config-build.in ] && awk '/config USE_APK/,/comment /' config/Config-build.in | grep -q 'depends on BROKEN'; then
  for fd in feeds/luci feeds/packages feeds/all; do
    [ -d "$fd" ] && find "$fd" -type f \( -name 'Makefile' -o -name '*.mk' \) -exec sed -i 's/+wget-any/+wget-ssl/g' {} + || true
  done
fi

# Prioritize luci-app-doanduy-modem ownership of modem_ctrl & 11_modem.js (prevent apk/opkg clash with qmodem)
rm -f \
  feeds/qmodem/application/qmodem/files/usr/libexec/rpcd/modem_ctrl \
  feeds/qmodem/luci/luci-app-qmodem/htdocs/luci-static/resources/view/status/include/11_modem.js \
  feeds/qmodem/luci/luci-app-qmodem-next/htdocs/luci-static/resources/view/status/include/11_modem.js \
  feeds/all/qmodem/files/usr/libexec/rpcd/modem_ctrl \
  feeds/all/luci-app-qmodem/htdocs/luci-static/resources/view/status/include/11_modem.js 2>/dev/null || true

# Fix haproxy 3.0.x / 3.2.x USE_QUIC=1 & USE_QUIC_OPENSSL_COMPAT=1 build failure against OpenSSL 3.x
if [ -f feeds/packages/net/haproxy/Makefile ]; then
  sed -i '/USE_QUIC=1/d; /USE_QUIC_OPENSSL_COMPAT=1/d' feeds/packages/net/haproxy/Makefile
fi

# Prevent MULTI_PROFILE MediaTek image assembly failures when ubootmod devices declare preloader/fip ARTIFACTS without BL2 packages enabled
for mk in target/linux/mediatek/image/filogic.mk target/linux/mediatek/image/filogic-ext.mk; do
  if [ -f "$mk" ]; then
    sed -i '/^[[:space:]]*ARTIFACTS[[:space:]]*:=[[:space:]]*.*preloader\.bin/d; /^[[:space:]]*ARTIFACT\/preloader\.bin[[:space:]]*:=/d; /^[[:space:]]*ARTIFACT\/bl31-uboot\.fip[[:space:]]*:=/d' "$mk"
  fi
done

./scripts/feeds install -a

echo "=========================================================="
echo ">> [2/3] Applying Out-of-Tree Driver Compatibility Patches..."
echo "=========================================================="
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
echo ">> [3/3] Pre-flight Shell Syntax Gate (Fail-Fast)..."
echo "=========================================================="
for d in files/etc/init.d files/etc/uci-defaults files/usr/bin files/etc/hotplug.d \
         package/base-files/files/etc/uci-defaults package/base-files/files/usr/bin; do
  [ -d "$d" ] || continue
  find "$d" -type f -exec chmod +x {} + 2>/dev/null || true
  for sf in "$d"/*; do
    [ -f "$sf" ] || continue
    case "$sf" in *.enc|*.json|*.conf) continue ;; esac
    if head -n 1 "$sf" | grep -qE '^#!/(usr/)?bin/(ba)?sh'; then
      sh -n "$sf"
    elif [ "${d%uci-defaults}" != "$d" ]; then
      sh -n "$sf"
    fi
  done
done
echo "   [PASS] All uci-defaults & custom shell scripts passed sh -n gate"
# [/VERIFIED-GOLDEN]
