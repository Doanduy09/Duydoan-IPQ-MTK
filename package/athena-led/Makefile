# [VERIFIED-GOLDEN: athena-led-c-driver-makefile | 2026-11-27 | DO NOT MODIFY UNLESS TARGETED]
include $(TOPDIR)/rules.mk

PKG_NAME:=athena-led
PKG_VERSION:=2.0.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-or-later

include $(INCLUDE_DIR)/package.mk

define Package/athena-led
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Lightweight C Driver for JDCloud RE-CS-02 (Athena) Matrix & RGB LED
  DEPENDS:=@aarch64
endef

define Package/athena-led/description
  Ultra-lightweight pure-C driver (~20KB) for JDCloud RE-CS-02 (Athena AX6600)
  dual TM1628 27x5 LED matrix display, dynamic side status icons, front RGB
  status LED bar, night schedule, 5G/Mesh/NetSpeed telemetry, and BTN_1 toggle.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) -O2 -Wall -Wextra -std=gnu11 \
		$(TARGET_LDFLAGS) \
		-o $(PKG_BUILD_DIR)/athena-led $(PKG_BUILD_DIR)/athena-led.c
endef

define Package/athena-led/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/athena-led $(1)/usr/sbin/athena-led
endef

$(eval $(call BuildPackage,athena-led))
# [/VERIFIED-GOLDEN]
