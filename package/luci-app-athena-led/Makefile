# [VERIFIED-GOLDEN: luci-app-athena-led-pro-makefile | 2026-11-27 | DO NOT MODIFY UNLESS TARGETED]
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-athena-led
PKG_VERSION:=2.0.0
PKG_RELEASE:=20261127

LUCI_TITLE:=Quản Trị Màn Hình LED & Đèn RGB JDCloud Athena (RE-CS-02)
LUCI_DEPENDS:=+luci-base +athena-led @aarch64
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/conffiles
/etc/config/athena_led
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
# [/VERIFIED-GOLDEN]
