#!/usr/bin/env bash
# Unified Pre-Build Preparation & Security/Syntax Gate (Duydoan-IPQ-MTK)
set -euo pipefail

echo "=========================================================="
echo ">> [1/4] Updating & Installing OpenWrt Feeds..."
echo "=========================================================="
# Embed DoanDuy Modem Suite directly into package/ (always refresh latest GitHub main)
rm -rf package/luci-app-doanduy-modem /tmp/doanduy-modem
git clone --depth 1 https://github.com/Doanduy09/luci-app-doanduy-modem.git /tmp/doanduy-modem
cp -r /tmp/doanduy-modem/luci-app-doanduy-modem package/
rm -rf /tmp/doanduy-modem

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
./scripts/feeds install -a

echo "=========================================================="
echo ">> [2/4] Applying Kernel 6.12 Out-of-Tree Driver Patches..."
echo "=========================================================="
# Fix -Werror=missing-prototypes on Linux Kernel 6.12 (GCC 13+)
for f in \
  feeds/all/fibocom_QMI_WWAN/src/qmi_wwan_f.c \
  feeds/qmodem/driver/fibocom_QMI_WWAN/src/qmi_wwan_f.c; do
  if [ -f "$f" ]; then
    sed -i 's/^int qma_setting_store/static int qma_setting_store/g' "$f"
    sed -i 's/int qma_setting_store/static int qma_setting_store/g' "$f"
    sed -i 's/static static int qma_setting_store/static int qma_setting_store/g' "$f"
    echo "   Patched Fibocom QMI: $f"
  fi
done

for f in \
  feeds/all/simcom_QMI_WWAN/src/qmi_wwan_s.c \
  feeds/qmodem/driver/simcom_QMI_WWAN/src/qmi_wwan_s.c; do
  if [ -f "$f" ]; then
    sed -i 's/^struct sk_buff \*qmi_wwan_tx_fixup/static struct sk_buff \*qmi_wwan_tx_fixup/g' "$f"
    sed -i 's/struct sk_buff \*qmi_wwan_tx_fixup/static struct sk_buff \*qmi_wwan_tx_fixup/g' "$f"
    sed -i 's/static static struct sk_buff \*qmi_wwan_tx_fixup/static struct sk_buff \*qmi_wwan_tx_fixup/g' "$f"
    echo "   Patched SIMCom QMI: $f"
  fi
done

# Fix qca-nss-ecm modpost undefined nss_rmnet_rx_get_ifnum on IPQ60xx
for f in \
  feeds/nss_packages/qca-nss-ecm/Makefile \
  package/feeds/nss_packages/qca-nss-ecm/Makefile; do
  if [ -f "$f" ]; then
    sed -i 's/ECM_INTERFACE_RAWIP_ENABLE=y/ECM_INTERFACE_RAWIP_ENABLE=n/g' "$f"
    echo "   Patched ECM RawIP rmnet: $f"
  fi
done

echo "=========================================================="
echo ">> [3/4] Decrypting Protected Assets (Zero-Leak Mode)..."
echo "=========================================================="
ENC_FILE="package/base-files/files/etc/init.d/all.enc"
TARGET_FILE="package/base-files/files/etc/init.d/all"
if [ -f "$ENC_FILE" ] && [ -n "${ALL_SECRET_KEY:-}" ]; then
  set +x
  openssl enc -d -aes-256-cbc -pbkdf2 -pass env:ALL_SECRET_KEY -in "$ENC_FILE" | zcat > "$TARGET_FILE"
  chmod 755 "$TARGET_FILE"
  echo "   Decrypted $TARGET_FILE ($(wc -c < "$TARGET_FILE") bytes)"
else
  echo "!! WARN: Missing $ENC_FILE or ALL_SECRET_KEY!"
  exit 1
fi

echo "=========================================================="
echo ">> [4/4] Pre-flight Shell Syntax Gate (Fail-Fast)..."
echo "=========================================================="
if [ -f "$TARGET_FILE" ]; then
  sh -n "$TARGET_FILE"
  echo "   [PASS] Syntax check passed for $TARGET_FILE"
fi
