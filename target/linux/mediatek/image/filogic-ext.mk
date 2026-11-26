define Device/clx_s20-common
  DEVICE_VENDOR := CLX
  DEVICE_DTS_DIR := ../dts-ext
  DEVICE_PACKAGES := kmod-usb3 kmod-mmc kmod-nvme \
    kmod-fs-f2fs kmod-fs-ext4 kmod-fs-vfat \
    mkf2fs f2fsck e2fsprogs blkid blockdev losetup automount
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

define Device/clx_s20l
  $(call Device/clx_s20-common)
  DEVICE_MODEL := S20L
  DEVICE_DTS := mt7986a-clx-s20l
endef
TARGET_DEVICES += clx_s20l

define Device/clx_s20m
  $(call Device/clx_s20-common)
  DEVICE_MODEL := S20M
  DEVICE_DTS := mt7986a-clx-s20m
  DEVICE_PACKAGES += -wpad-openssl -kmod-mt_wifi -kmod-conninfra -kmod-warp \
    -wifi-dats -wifi-profile -mtwifi-cfg -mtwifi-cfg-ucode \
    -luci-app-mtwifi-cfg -luci-i18n-mtwifi-cfg-zh-cn \
    -kmod-mt76 -kmod-mt76-connac -kmod-mt76-core -kmod-mt7915e \
    -kmod-mt7915-firmware -kmod-mt7916-firmware -kmod-mt7986-firmware \
    -mt7986-wo-firmware
endef
TARGET_DEVICES += clx_s20m

define Device/clx_s20p
  $(call Device/clx_s20-common)
  DEVICE_MODEL := S20P
  DEVICE_DTS := mt7986a-clx-s20p
endef
TARGET_DEVICES += clx_s20p

define Device/cmcc_xr30-nand-mtkuboot
  DEVICE_VENDOR := CMCC
  DEVICE_MODEL := XR30 NAND
  DEVICE_VARIANT := (MTK U-Boot layout)
  DEVICE_DTS := mt7981b-cmcc-xr30-nand-mtkuboot
  DEVICE_DTS_DIR := ../dts-ext
  DEVICE_PACKAGES := kmod-usb3 automount
  SUPPORTED_DEVICES := cmcc,xr30-mtkuboot
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 116736k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin sysupgrade.itb
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
endef
TARGET_DEVICES += cmcc_xr30-nand-mtkuboot

define Device/cudy_tr3000-v1-mtkuboot
  DEVICE_VENDOR := Cudy
  DEVICE_MODEL := TR3000
  DEVICE_VARIANT := v1 (MTK U-Boot layout)
  DEVICE_DTS := mt7981b-cudy-tr3000-v1-mtkuboot
  DEVICE_DTS_DIR := ../dts-ext
  SUPPORTED_DEVICES += R47
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 114688k
  KERNEL_IN_UBI := 1
  IMAGES := sysupgrade.bin sysupgrade.itb
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
  DEVICE_PACKAGES := kmod-usb3 automount
endef
TARGET_DEVICES += cudy_tr3000-v1-mtkuboot

define Device/h3c_magic-nx30-pro-mtkuboot
  DEVICE_VENDOR := H3C
  DEVICE_MODEL := Magic NX30 Pro
  DEVICE_VARIANT := (MTK U-Boot layout)
  DEVICE_DTS := mt7981b-h3c-magic-nx30-pro-mtkuboot
  DEVICE_DTS_DIR := ../dts-ext
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 65536k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin sysupgrade.itb
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
endef
TARGET_DEVICES += h3c_magic-nx30-pro-mtkuboot

define Device/netcore_n60-pro-mtkuboot
  DEVICE_VENDOR := Netcore
  DEVICE_MODEL := N60 Pro
  DEVICE_VARIANT := (MTK U-Boot layout)
  DEVICE_DTS := mt7986a-netcore-n60-pro-mtkuboot
  DEVICE_DTS_DIR := ../dts-ext
  DEVICE_PACKAGES := kmod-usb3 automount kmod-usb-ledtrig-usbport 
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin sysupgrade.itb
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
endef
TARGET_DEVICES += netcore_n60-pro-mtkuboot

define Device/ruijie_rg-x30e-pro
  DEVICE_VENDOR := Ruijie
  DEVICE_MODEL := RG-X30E Pro
  DEVICE_DTS := mt7981b-ruijie-rg-x30e-pro
  DEVICE_DTS_DIR := ../dts-ext
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 114688k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin sysupgrade.itb
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
endef
TARGET_DEVICES += ruijie_rg-x30e-pro

define Device/ruijie_rg-x60-new-mtkuboot
  DEVICE_VENDOR := Ruijie
  DEVICE_MODEL := RG-X60 New
  DEVICE_VARIANT := (MTK U-Boot layout)
  DEVICE_DTS := mt7986a-ruijie-rg-x60-new-mtkuboot
  DEVICE_DTS_DIR := ../dts-ext
  DEVICE_PACKAGES := kmod-phy-airoha-en8811h kmod-mtd-rw
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += ruijie_rg-x60-new-mtkuboot

define Device/ruijie_rg-x60-new-ubi
  DEVICE_VENDOR := Ruijie
  DEVICE_MODEL := RG-X60 New
  DEVICE_VARIANT := (UBI)
  DEVICE_DTS := mt7986a-ruijie-rg-x60-new-ubi
  DEVICE_DTS_DIR := ../dts-ext
  DEVICE_PACKAGES := kmod-phy-airoha-en8811h kmod-mtd-rw
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
  fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.itb := append-kernel | \
  fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb \
  external-with-rootfs | pad-rootfs | append-metadata
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/bl31-uboot.fip := mt7986-bl31-uboot ruijie_rg-x60-new-ubi
  ARTIFACT/preloader.bin := mt7986-bl2 spim-nand-ubi-ddr3
endef
TARGET_DEVICES += ruijie_rg-x60-new-ubi

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := ../dts-ext
  DEVICE_PACKAGES := e2fsprogs f2fsck mkf2fs
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl_3000-emmc

define Device/viettel_32x6
  DEVICE_VENDOR := Viettel
  DEVICE_MODEL := 32X6
  DEVICE_DTS := mt7981b-viettel-32x6
  DEVICE_DTS_DIR := ../dts-ext
  SUPPORTED_DEVICES := viettel,32x6
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 114688k
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES := sysupgrade.itb sysupgrade.bin
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	append-metadata
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += viettel_32x6

define Device/viettel_nr3053
  DEVICE_VENDOR := Viettel
  DEVICE_MODEL := NR3053
  DEVICE_DTS := mt7981b-viettel-nr3053
  DEVICE_DTS_DIR := ../dts-ext
  SUPPORTED_DEVICES := viettel,nr3053
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 229376k
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES := sysupgrade.itb sysupgrade.bin
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	append-metadata
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += viettel_nr3053



define Device/wirelesstag_zx7981pd-ubootmod
  DEVICE_VENDOR := Wireless-Tag
  DEVICE_MODEL := ZX7981PD
  DEVICE_VARIANT := (OpenWrt U-Boot layout)
  DEVICE_DTS := mt7981b-wirelesstag-zx7981pd-ubootmod
  DEVICE_DTS_DIR := ../dts-ext
  DEVICE_PACKAGES := kmod-usb3
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES := sysupgrade.itb sysupgrade.bin
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  KERNEL := kernel-bin | lzma
  KERNEL_INITRAMFS := kernel-bin | lzma | \
        fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
        fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7981-bl2 spim-nand-ddr3
  ARTIFACT/bl31-uboot.fip := mt7981-bl31-uboot wirelesstag_zx7981pd
ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)
  ARTIFACTS += initramfs-factory.ubi
  ARTIFACT/initramfs-factory.ubi := append-image-stage initramfs-recovery.itb | ubinize-kernel
endif
endef
TARGET_DEVICES += wirelesstag_zx7981pd-ubootmod

define Device/xiaomi_mi-router-ax3000t-mtkuboot
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Mi Router AX3000T
  DEVICE_VARIANT := (MTK U-Boot layout)
  DEVICE_DTS := mt7981b-xiaomi-mi-router-ax3000t-mtkuboot
  DEVICE_DTS_DIR := ../dts-ext
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 114688k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin sysupgrade.itb
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
endef
TARGET_DEVICES += xiaomi_mi-router-ax3000t-mtkuboot

define Device/xiaomi_mi-router-wr30u-mtkuboot
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Mi Router WR30U
  DEVICE_VARIANT := (MTK U-Boot layout)
  DEVICE_DTS := mt7981b-xiaomi-mi-router-wr30u-mtkuboot
  DEVICE_DTS_DIR := ../dts-ext
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 114688k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin sysupgrade.itb
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
endef
TARGET_DEVICES += xiaomi_mi-router-wr30u-mtkuboot

define Device/xiaomi_redmi-router-ax6000-mtkuboot
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Redmi Router AX6000
  DEVICE_VARIANT := (MTK U-Boot layout)
  DEVICE_DTS := mt7986a-xiaomi-redmi-router-ax6000-mtkuboot
  DEVICE_DTS_DIR := ../dts-ext
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 112640k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin sysupgrade.itb
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
endef
TARGET_DEVICES += xiaomi_redmi-router-ax6000-mtkuboot

define Device/zhao_7981r128-mtkuboot
  DEVICE_VENDOR := ZHAO
  DEVICE_MODEL := 7981r128
  DEVICE_VARIANT := (MTK U-Boot layout)
  DEVICE_DTS := mt7981b-zhao-7981r128-mtkuboot
  DEVICE_DTS_DIR := ../dts-ext
  SUPPORTED_DEVICES := zhao,7981r128
  DEVICE_PACKAGES := kmod-usb3 kmod-sfp kmod-i2c-gpio automount f2fsck mkf2fs
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 114688k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin sysupgrade.itb
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
endef
TARGET_DEVICES += zhao_7981r128-mtkuboot

# --- Additional Devices from quytttb with Dual Image Support (.bin & .itb) ---
define Device/acer_predator-w6x-stock
  DEVICE_VENDOR := Acer
  DEVICE_MODEL := Predator Connect W6x (Stock Layout)
  DEVICE_DTS := mt7986a-acer-predator-w6x-stock
  SUPPORTED_DEVICES += acer,predator-w6x
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTS_LOADADDR := 0x47000000
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  DEVICE_PACKAGES := kmod-usb3 kmod-leds-ws2812b automount
  IMAGES := sysupgrade.bin
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += acer_predator-w6x-stock

define Device/acer_predator-w6x-ubootmod
  DEVICE_VENDOR := Acer
  DEVICE_MODEL := Predator Connect W6x (OpenWrt U-Boot Layout)
  DEVICE_DTS := mt7986a-acer-predator-w6x-ubootmod
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-usb3 kmod-leds-ws2812b automount
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7986-bl2 spim-nand-ddr4
  ARTIFACT/bl31-uboot.fip := mt7986-bl31-uboot acer_predator-w6x
endef
TARGET_DEVICES += acer_predator-w6x-ubootmod

define Device/asiarf_ap7986-003
  DEVICE_VENDOR := AsiaRF
  DEVICE_MODEL := AP7986 003
  DEVICE_DTS := mt7986a-asiarf-ap7986-003
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-usb3 automount
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 65536k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += asiarf_ap7986-003

define Device/aigo_ags21
  DEVICE_VENDOR := AIGO
  DEVICE_MODEL := AGS21
  DEVICE_DTS := mt7981b-aigo-ags21
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTC_FLAGS := --pad 4096
  DEVICE_DTS_LOADADDR := 0x43f00000
  DEVICE_PACKAGES := f2fsck mkf2fs
  KERNEL_LOADADDR := 0x44000000
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
        fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE_SIZE := $$(shell expr 64 + $$(CONFIG_TARGET_ROOTFS_PARTSIZE))m
  IMAGE/sysupgrade.itb := append-kernel | \
        fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
        pad-rootfs | append-metadata
  ARTIFACTS := emmc-gpt.bin
  ARTIFACT/emmc-gpt.bin := mt798x-gpt emmc
  ARTIFACTS += emmc-preloader.bin emmc-bl31-uboot.fip
  ARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr4
  ARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot aigo_ags21
endef
TARGET_DEVICES += aigo_ags21

define Device/airpi_ap3000m
  DEVICE_VENDOR := Airpi
  DEVICE_MODEL := AP3000M
  DEVICE_DTS := mt7981b-airpi-ap3000m
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware \
	kmod-hwmon-pwmfan kmod-usb3 f2fsck mkf2fs automount
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
        fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEFAULT := n
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += airpi_ap3000m

define Device/airtel_aap4221zy
  DEVICE_VENDOR := Airtel
  DEVICE_MODEL := AirFiber AAP4221ZY
  DEVICE_ALT0_VENDOR := Zyxel
  DEVICE_ALT0_MODEL := EX3310-T0
  DEVICE_DTS := mt7981b-airtel-aap4221zy
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-ledtrig-network kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 256k
  PAGESIZE := 4096
  IMAGE_SIZE := 131072k
  KERNEL_IN_UBI := 1
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += airtel_aap4221zy

define Device/asus_rt-ax57m
  DEVICE_VENDOR := ASUS
  DEVICE_MODEL := RT-AX57M
  DEVICE_ALT0_VENDOR := ASUS
  DEVICE_ALT0_MODEL := RT-AX54HP
  DEVICE_ALT0_VARIANT := V2
  DEVICE_ALT1_VENDOR := ASUS
  DEVICE_ALT1_MODEL := RT-AX1800HP
  DEVICE_ALT1_VARIANT := V2
  DEVICE_ALT2_VENDOR := ASUS
  DEVICE_ALT2_MODEL := RT-AX1800S
  DEVICE_ALT2_VARIANT := V2
  DEVICE_ALT3_VENDOR := ASUS
  DEVICE_ALT3_MODEL := RT-AX3000S
  DEVICE_DTS := mt7981b-asus-rt-ax57m
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
  IMAGES := sysupgrade.bin
  KERNEL := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
ifeq ($(IB),)
  ARTIFACTS := initramfs.trx
  ARTIFACT/initramfs.trx := append-image-stage initramfs-kernel.bin | \
	uImage none | asus-trx -v 3 -n $$(DEVICE_MODEL)
endif
endef
TARGET_DEVICES += asus_rt-ax57m

define Device/asus_zenwifi-bt8
  DEVICE_VENDOR := ASUS
  DEVICE_MODEL := ZenWiFi BT8
  DEVICE_DTS := mt7988d-asus-zenwifi-bt8
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-usb3 mt7988-2p5g-phy-firmware kmod-mt7996-firmware mt7988-wo-firmware automount
  KERNEL := kernel-bin | gzip | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_LOADADDR := 0x48080000
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
ifeq ($(IB),)
ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)
  ARTIFACTS := factory.bin
  ARTIFACT/factory.bin := append-image initramfs-kernel.bin | uImage lzma
endif
endif
endef
TARGET_DEVICES += asus_zenwifi-bt8

define Device/asus_zenwifi-bt8-ubootmod
  DEVICE_VENDOR := ASUS
  DEVICE_MODEL := ZenWiFi BT8
  DEVICE_VARIANT := U-Boot mod
  DEVICE_DTS := mt7988d-asus-zenwifi-bt8-ubootmod
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTS_LOADADDR := 0x45f00000
  DEVICE_PACKAGES := kmod-usb3 mt7988-2p5g-phy-firmware kmod-mt7996-firmware mt7988-wo-firmware automount
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7988-bl2 spim-nand-ubi-ddr4
  ARTIFACT/bl31-uboot.fip := mt7988-bl31-uboot asus_zenwifi-bt8
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL_LOADADDR := 0x46000000
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/sysupgrade.itb := append-kernel | fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-with-rootfs | pad-rootfs | append-metadata
endef
TARGET_DEVICES += asus_zenwifi-bt8-ubootmod

define Device/bananapi_bpi-r4-lite
  DEVICE_VENDOR := Bananapi
  DEVICE_MODEL := BPi-R4 Lite
  DEVICE_DTS := mt7987a-bananapi-bpi-r4-lite
  DEVICE_DTS_OVERLAY:= mt7987a-bananapi-bpi-r4-lite-1pcie-2L mt7987a-bananapi-bpi-r4-lite-2pcie-1L \
		       mt7987a-bananapi-bpi-r4-lite-emmc mt7987a-bananapi-bpi-r4-lite-sd \
		       mt7987a-bananapi-bpi-r4-lite-nand mt7987a-bananapi-bpi-r4-lite-nor
  DEVICE_DTS_CONFIG := config-mt7987a-bananapi-bpi-r4-lite
  DEVICE_DTC_FLAGS := --pad 4096
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTS_LOADADDR := 0x4ff00000
  DEVICE_PACKAGES := kmod-eeprom-at24 kmod-gpio-pca953x kmod-i2c-mux-pca954x automount \
		     kmod-rtc-pcf8563 kmod-sfp kmod-usb3 e2fsprogs mkf2fs mt7987-2p5g-phy-firmware
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  KERNEL_LOADADDR := 0x40000000
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL_IN_UBI := 1
  IMAGES := sysupgrade.itb
  IMAGE/sysupgrade.itb := append-kernel | fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-with-rootfs | pad-rootfs | append-metadata
  ARTIFACTS := \
	       emmc-preloader.bin emmc-bl31-uboot.fip \
	       nor-preloader.bin nor-bl31-uboot.fip \
	       sdcard.img.gz \
	       snand-preloader.bin snand-bl31-uboot.fip
  ARTIFACT/emmc-preloader.bin	:= mt7987-bl2 emmc-comb
  ARTIFACT/emmc-bl31-uboot.fip	:= mt7987-bl31-uboot bananapi_bpi-r4-lite-emmc
  ARTIFACT/nor-preloader.bin	:= mt7987-bl2 nor-comb
  ARTIFACT/nor-bl31-uboot.fip	:= mt7987-bl31-uboot bananapi_bpi-r4-lite-nor
  ARTIFACT/snand-preloader.bin	:= mt7987-bl2 spim-nand2-ubi-comb
  ARTIFACT/snand-bl31-uboot.fip	:= mt7987-bl31-uboot bananapi_bpi-r4-lite-snand
  ARTIFACT/sdcard.img.gz	:= mt798x-gpt sdmmc |\
				   pad-to 17k | mt7987-bl2 sdmmc-comb |\
				   pad-to 6656k | mt7987-bl31-uboot bananapi_bpi-r4-lite-sdmmc |\
				$(if $(CONFIG_TARGET_ROOTFS_INITRAMFS),\
				   pad-to 12M | append-image-stage initramfs-recovery.itb | check-size 44m |\
				) \
				   pad-to 44M | mt7987-bl2 spim-nand2-ubi-comb |\
				   pad-to 45M | mt7987-bl31-uboot bananapi_bpi-r4-lite-snand |\
				   pad-to 49M | mt7987-bl2 nor-comb |\
				   pad-to 50M | mt7987-bl31-uboot bananapi_bpi-r4-lite-nor |\
				   pad-to 51M | mt7987-bl2 emmc-comb |\
				   pad-to 52M | mt7987-bl31-uboot bananapi_bpi-r4-lite-emmc |\
				   pad-to 56M | mt798x-gpt emmc |\
				$(if $(CONFIG_TARGET_ROOTFS_SQUASHFS),\
				   pad-to 64M | append-image squashfs-sysupgrade.itb | check-size |\
				) \
				  gzip
ifeq ($(DUMP),)
  IMAGE_SIZE := $$(shell expr 64 + $$(CONFIG_TARGET_ROOTFS_PARTSIZE))m
endif
endef
ifeq ($(KERNEL_PATCHVER),6.12)
TARGET_DEVICES += bananapi_bpi-r4-lite
endif

define Device/bazis_ax3000wm
  DEVICE_VENDOR := Bazis
  DEVICE_MODEL := AX3000WM
  DEVICE_ALT0_VENDOR := Shenzhen Jia Yan Technology
  DEVICE_ALT0_MODEL := WD-R3000N-G2A
  DEVICE_DTS := mt7981b-bazis-ax3000wm
  DEVICE_DTS_DIR := ../dts
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	append-metadata
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware automount
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7981-bl2 spim-nand-ddr3
  ARTIFACT/bl31-uboot.fip := mt7981-bl31-uboot bazis-ax3000wm
endef
TARGET_DEVICES += bazis_ax3000wm

define Device/buffalo_wsr-6000ax8
  DEVICE_MODEL := WSR-6000AX8
  DEVICE_VENDOR := Buffalo
  DEVICE_ALT0_MODEL := WSR-6000AX8P
  DEVICE_ALT0_VENDOR := Buffalo
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTS := mt7986b-buffalo-wsr-6000ax8
  DEVICE_PACKAGES :=   
  IMAGE_SIZE := 26624k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += buffalo_wsr-6000ax8

define Device/cudy_ap3000wall-v1
  DEVICE_VENDOR := Cudy
  DEVICE_MODEL := AP3000 Wall
  DEVICE_VARIANT := v1
  DEVICE_DTS := mt7981b-cudy-ap3000wall-v1
  DEVICE_DTS_DIR := ../dts
  SUPPORTED_DEVICES += R68
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 65536k
  KERNEL_IN_UBI := 1
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += cudy_ap3000wall-v1

define Device/elecom_wrc-x3000gs3
  DEVICE_VENDOR := ELECOM
  DEVICE_MODEL := WRC-X3000GS3
  DEVICE_DTS := mt7981b-elecom-wrc-x3000gs3
  DEVICE_DTS_DIR := ../dts
  IMAGES += factory.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/factory.bin := sysupgrade-tar | mstc-header 5.04(XZQ.0)b90 COMD | \
	elecom-product-header WRC-X3000GS3
  DEVICE_PACKAGES := 
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += elecom_wrc-x3000gs3

define Device/glinet_gl-mt3600be
  DEVICE_VENDOR := GL.iNet
  DEVICE_MODEL := GL-MT3600BE
  DEVICE_DTS := mt7987a-glinet-gl-mt3600be
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := mt7987-2p5g-phy-firmware kmod-mt7990-firmware \
	kmod-hwmon-pwmfan kmod-usb3 automount
  KERNEL = kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS = kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd
  KERNEL_IN_UBI := 1
  KERNEL_LOADADDR := 0x40000000
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 483328k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
ifeq ($(KERNEL_PATCHVER),6.12)
TARGET_DEVICES += glinet_gl-mt3600be
endif

define Device/globitel_bt-r320
  DEVICE_VENDOR := Globitel
  DEVICE_MODEL := BT-R320
  DEVICE_DTS := mt7981b-globitel-bt-r320
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware f2fsck mkf2fs
  KERNEL_LOADADDR := 0x44000000
  KERNEL := kernel-bin | lzma
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE_SIZE := $$(shell expr 64 + $$(CONFIG_TARGET_ROOTFS_PARTSIZE))m
  IMAGE/sysupgrade.itb := append-kernel | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	pad-rootfs | append-metadata
  ARTIFACTS := gpt.bin preloader.bin bl31-uboot.fip
  ARTIFACT/gpt.bin := mt798x-gpt emmc
  ARTIFACT/preloader.bin := mt7981-bl2 emmc-ddr4
  ARTIFACT/bl31-uboot.fip := mt7981-bl31-uboot globitel_bt-r320
endef
TARGET_DEVICES += globitel_bt-r320

define Device/hiveton_h5000m
  DEVICE_VENDOR := Hiveton
  DEVICE_MODEL := H5000M
  DEVICE_ALT0_VENDOR := Airpi
  DEVICE_ALT0_MODEL := H5000M
  DEVICE_DTS := mt7987a-hiveton-h5000m
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-hwmon-pwmfan kmod-usb3 mt7987-2p5g-phy-firmware \
	kmod-mt7996e kmod-mt7992-23-firmware f2fsck mkf2fs automount
  KERNEL_LOADADDR := 0x40000000
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
ifeq ($(KERNEL_PATCHVER),6.12)
TARGET_DEVICES += hiveton_h5000m
endif

define Device/huasifei_wh3000-pro-emmc
  DEVICE_VENDOR := Huasifei
  DEVICE_MODEL := WH3000 Pro
  DEVICE_VARIANT := eMMC
  DEVICE_DTS := mt7981b-huasifei-wh3000-pro-emmc
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES :=    \
	kmod-hwmon-pwmfan kmod-usb3 f2fsck mkf2fs automount
  SUPPORTED_DEVICES += huasifei,wh3000-pro
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += huasifei_wh3000-pro-emmc

define Device/huasifei_wh3000-pro-nand
  DEVICE_VENDOR := Huasifei
  DEVICE_MODEL := WH3000 Pro
  DEVICE_VARIANT := NAND
  DEVICE_DTS := mt7981b-huasifei-wh3000-pro-nand
  DEVICE_DTS_DIR := ../dts
  IMAGE_SIZE := 231936k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware \
	kmod-usb3 kmod-hwmon-pwmfan automount
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += huasifei_wh3000-pro-nand

define Device/huasifei_wh3000r-nand
  DEVICE_VENDOR := Huasifei
  DEVICE_MODEL := WH3000R
  DEVICE_VARIANT := NAND
  DEVICE_DTS := mt7981b-huasifei-wh3000r-nand
  DEVICE_DTS_DIR := ../dts
  IMAGE_SIZE := 231936k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware \
	kmod-usb3 automount
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += huasifei_wh3000r-nand

define Device/imou_hx21
  DEVICE_VENDOR := Imou
  DEVICE_MODEL := HX21
  DEVICE_ALT0_VENDOR := Imou
  DEVICE_ALT0_MODEL := LC-HX3001
  DEVICE_DTS := mt7981b-imou-hx21
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := 
  SUPPORTED_DEVICES += imou,lc-hx3001
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7981-bl2 spim-nand-ddr3
  ARTIFACT/bl31-uboot.fip := mt7981-bl31-uboot imou_hx21
endef
TARGET_DEVICES += imou_hx21

define Device/iptime_ax3000se
  DEVICE_VENDOR := ipTIME
  DEVICE_MODEL := AX3000SE
  DEVICE_DTS := mt7981b-iptime-ax3000se
  DEVICE_DTS_DIR := ../dts
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 32768k
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGES := sysupgrade.bin
  IMAGES := factory.bin sysupgrade.bin
  IMAGE/factory.bin := sysupgrade-tar | append-metadata | check-size | iptime-crc32 ax3kse
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES := kmod-ledtrig-network
  SUPPORTED_DEVICES += mediatek,mt7981-spim-snand-rfb
endef
TARGET_DEVICES += iptime_ax3000se

define Device/iptime_ax3000m
  DEVICE_VENDOR := ipTIME
  DEVICE_MODEL := AX3000M
  DEVICE_DTS := mt7981b-iptime-ax3000m
  DEVICE_DTS_DIR := ../dts
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 32768k
  KERNEL := kernel-bin | lzma | \
	    fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGES := factory.bin sysupgrade.bin
  IMAGE/factory.bin := sysupgrade-tar | append-metadata | check-size | iptime-crc32 ax3000m
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES := 
  SUPPORTED_DEVICES += mediatek,mt7981-spim-snand-rfb
endef
TARGET_DEVICES += iptime_ax3000m

define Device/jiorouter_ax6000-jidu6101
  DEVICE_VENDOR := JioRouter
  DEVICE_MODEL := AX6000
  DEVICE_VARIANT := JIDU6101
  DEVICE_DTS := mt7986a-jiorouter-ax6000-jidu6101
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7986-firmware mt7986-wo-firmware automount
  UBINIZE_OPTS := -E 5
  UBOOTENV_IN_UBI := 1
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += jiorouter_ax6000-jidu6101

define Device/jiorouter_ax6000-jidu6j01
  DEVICE_VENDOR := JioRouter
  DEVICE_MODEL := AX6000
  DEVICE_VARIANT := JIDU6J01
  DEVICE_ALT0_VENDOR := JioRouter
  DEVICE_ALT0_MODEL := AX6000
  DEVICE_ALT0_VARIANT := JIDU6201
  DEVICE_ALT1_VENDOR := JioRouter
  DEVICE_ALT1_MODEL := AX6000
  DEVICE_ALT1_VARIANT := JIDU6401
  DEVICE_ALT2_VENDOR := JioRouter
  DEVICE_ALT2_MODEL := AX6000
  DEVICE_ALT2_VARIANT := JIDU6601
  DEVICE_ALT3_VENDOR := JioRouter
  DEVICE_ALT3_MODEL := AX6000
  DEVICE_ALT3_VARIANT := JIDU6701
  DEVICE_DTS := mt7986a-jiorouter-ax6000-jidu6j01
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7986-firmware mt7986-wo-firmware
  UBINIZE_OPTS := -E 5
  UBOOTENV_IN_UBI := 1
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += jiorouter_ax6000-jidu6j01

define Device/kebidumei_ax3000-u22
  DEVICE_VENDOR := Kebidumei
  DEVICE_MODEL := AX3000-U22
  DEVICE_DTS := mt7981b-kebidumei-ax3000-u22
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTS_LOADADDR := 0x43f00000
  IMAGE_SIZE := 14848k
  KERNEL_LOADADDR := 0x44000000
  KERNEL := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  DEVICE_PACKAGES := 
  SUPPORTED_DEVICES += mediatek,mt7981-spim-nor-rfb
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += kebidumei_ax3000-u22

define Device/keenetic_kap-630-common
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware \
		kmod-phy-airoha-en8811h
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 6144k
  IMAGE_SIZE := 108544k
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb | \
	append-squashfs4-fakeroot
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | \
	append-ubi | check-size | zyimage -d $$(ZYIMAGE_ID) -v "$$(DEVICE_MODEL)"
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

define Device/keenetic_kap-630
  DEVICE_VENDOR := Keenetic
  DEVICE_MODEL := KAP-630
  DEVICE_DTS := mt7981b-keenetic-kap-630
  ZYIMAGE_ID := 0x810630
  $(call Device/keenetic_kap-630-common)
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += keenetic_kap-630

define Device/keenetic_kn-1812-common
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7992-firmware kmod-usb3 automount \
		mt7988-2p5g-phy-firmware mt7988-wo-firmware
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 6144k
  IMAGE_SIZE := 229888k
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb | \
	append-squashfs4-fakeroot
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | \
	append-ubi | check-size | zyimage -d $$(ZYIMAGE_ID) -v "$$(DEVICE_MODEL)"
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

define Device/keenetic_kn-1812
  DEVICE_VENDOR := Keenetic
  DEVICE_MODEL := KN-1812
  DEVICE_DTS := mt7988d-keenetic-kn-1812
  ZYIMAGE_ID := 0x801812
  $(call Device/keenetic_kn-1812-common)
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += keenetic_kn-1812

define Device/keenetic_kn-3711
  DEVICE_VENDOR := Keenetic
  DEVICE_MODEL := KN-3711
  DEVICE_DTS := mt7981b-keenetic-kn-3711
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := 
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 6144k
  IMAGE_SIZE := 108544k
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb | \
	append-squashfs4-fakeroot
  IMAGES += factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | \
	append-ubi | check-size | zyimage -d 0x803711 -v "KN-3711"
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += keenetic_kn-3711

define Device/livinet_li320
  DEVICE_VENDOR := Livinet
  DEVICE_MODEL := Li320
  DEVICE_DTS := mt7981b-livinet-li320
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  SUPPORTED_DEVICES += mediatek,mt7981-spim-snand-gsw-rfb
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += livinet_li320

define Device/mediatek_mt7987a-rfb
  DEVICE_VENDOR := MediaTek
  DEVICE_MODEL := MT7987A rfb
  DEVICE_DTS := mt7987a-rfb
  DEVICE_DTS_OVERLAY:= \
	mt7987a-rfb-spim-nand \
	mt7987a-rfb-spim-nor \
	mt7987a-rfb-emmc \
	mt7987a-rfb-sd \
	mt7987a-rfb-eth0-an8801sb \
	mt7987a-rfb-eth0-an8855 \
	mt7987a-rfb-eth0-e2p5g \
	mt7987a-rfb-eth0-mt7531 \
	mt7987a-rfb-eth1-i2p5g \
	mt7987a-rfb-eth2-an8801sb \
	mt7987a-rfb-eth2-e2p5g \
	mt7987a-rfb-eth2-sfp \
	mt7987a-rfb-eth2-usb
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTC_FLAGS := --pad 4096
  DEVICE_DTS_LOADADDR := 0x4ff00000
  DEVICE_PACKAGES := mt7987-2p5g-phy-firmware kmod-sfp
  KERNEL_LOADADDR := 0x40000000
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL_INITRAMFS_SUFFIX := .itb
  KERNEL_IN_UBI := 1
  IMAGE_SIZE := $$(shell expr 64 + $$(CONFIG_TARGET_ROOTFS_PARTSIZE))m
  IMAGES := sysupgrade.itb
  IMAGE/sysupgrade.itb := append-kernel | fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-with-rootfs | pad-rootfs | append-metadata
  ARTIFACTS := \
	snand-preloader.bin \
	snand-bl31-uboot.fip \
	sdcard.img.gz
  ARTIFACT/snand-preloader.bin	:= mt7987-bl2 spim-nand0-ubi-comb
  ARTIFACT/snand-bl31-uboot.fip	:= mt7987-bl31-uboot rfb-spim-nand
  ARTIFACT/sdcard.img.gz	:= mt798x-gpt sdmmc |\
				   pad-to 17k | mt7987-bl2 sdmmc-comb |\
				   pad-to 6656k | mt7987-bl31-uboot rfb-sd |\
				$(if $(CONFIG_TARGET_ROOTFS_INITRAMFS),\
				  pad-to 12M | append-image-stage initramfs.itb | check-size 44m |\
				) \
				$(if $(CONFIG_TARGET_ROOTFS_SQUASHFS),\
				  pad-to 64M | append-image squashfs-sysupgrade.itb | check-size |\
				) \
				  gzip
endef
ifeq ($(KERNEL_PATCHVER),6.12)
TARGET_DEVICES += mediatek_mt7987a-rfb
endif

define Device/mercusys_mr85x
  DEVICE_VENDOR := MERCUSYS
  DEVICE_MODEL := MR85X
  DEVICE_DTS := mt7981b-mercusys-mr85x
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES :=  kmod-phy-airoha-en8811h swconfig kmod-switch-rtl8367s
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += mercusys_mr85x

define Device/netcraze_nap-630
  DEVICE_VENDOR := Netcraze
  DEVICE_MODEL := NAP-630
  DEVICE_DTS := mt7981b-netcraze-nap-630
  ZYIMAGE_ID := 0xC10630
  $(call Device/keenetic_kap-630-common)
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += netcraze_nap-630

define Device/netcraze_nc-1812
  DEVICE_VENDOR := Netcraze
  DEVICE_MODEL := NC-1812
  DEVICE_DTS := mt7988d-netcraze-nc-1812
  ZYIMAGE_ID := 0xC01812
  $(call Device/keenetic_kn-1812-common)
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += netcraze_nc-1812

define Device/netgear_eax17
  DEVICE_VENDOR := NETGEAR
  DEVICE_MODEL := EAX17
  DEVICE_ALT0_VENDOR := NETGEAR
  DEVICE_ALT0_MODEL := EAX11
  DEVICE_ALT0_VARIANT := v3
  DEVICE_ALT1_VENDOR := NETGEAR
  DEVICE_ALT1_MODEL := EAX15
  DEVICE_ALT1_VARIANT := v3
  DEVICE_ALT2_VENDOR := NETGEAR
  DEVICE_ALT2_MODEL := EAX14
  DEVICE_ALT2_VARIANT := v3
  DEVICE_ALT3_VENDOR := NETGEAR
  DEVICE_ALT3_MODEL := EAX12
  DEVICE_ALT3_VARIANT := v2
  DEVICE_ALT4_VENDOR := NETGEAR
  DEVICE_ALT4_MODEL := EAX16
  DEVICE_ALT5_VENDOR := NETGEAR
  DEVICE_ALT5_MODEL := EAX19
  DEVICE_DTS := mt7981b-netgear-eax17
  DEVICE_DTS_DIR := ../dts
  SUPPORTED_DEVICES += mediatek,mt7981-spim-snand-rfb
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  NETGEAR_ENC_MODEL := EAX17
  NETGEAR_ENC_REGION := US
  NETGEAR_ENC_HW_ID_LIST := 1010000013120000_NETGEAR
  NETGEAR_ENC_MODEL_LIST := EAX17;EAX11v3;EAX15v3;EAX14v3;EAX12v2;EAX16;EAX19
  DEVICE_PACKAGES := 
  KERNEL = kernel-bin | lzma | \
	fit-with-netgear-top-level-rootfs-node lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_IN_UBI := 1
  IMAGE_SIZE := 81920k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES += factory.img
  # Padding to 10M seems to be required by OEM web interface
  IMAGE/factory.img := sysupgrade-tar | \
	  pad-to 10M | check-size | netgear-encrypted-factory
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += netgear_eax17

define Device/netis_eap930-v1
  DEVICE_VENDOR := netis
  DEVICE_MODEL := EAP930 V1
  DEVICE_DTS := mt7981b-netis-eap930-v1
  DEVICE_DTS_DIR := ../dts
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	append-metadata
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7981-bl2 spim-nand-ddr3
  ARTIFACT/bl31-uboot.fip := mt7981-bl31-uboot netis_eap930-v1
endef
TARGET_DEVICES += netis_eap930-v1

define Device/netis_n6-v2
  DEVICE_VENDOR := netis
  DEVICE_MODEL := N6 V2
  DEVICE_DTS := mt7981b-netis-n6-v2
  DEVICE_DTS_DIR := ../dts
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL := kernel-bin | libdeflate-gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	append-metadata
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware \
	kmod-usb3 kmod-usb-ledtrig-usbport
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7981-bl2 spim-nand-ddr3-1866
  ARTIFACT/bl31-uboot.fip := mt7981-bl31-uboot netis_n6-v2
endef
TARGET_DEVICES += netis_n6-v2

define Device/netis_nx30v2
  DEVICE_VENDOR := netis
  DEVICE_MODEL := NX30
  DEVICE_VARIANT := V2
  DEVICE_ALT0_VENDOR := Netcore
  DEVICE_ALT0_MODEL := POWER 30AX
  DEVICE_ALT1_VENDOR := Netcore
  DEVICE_ALT1_MODEL := N30 Pro
  DEVICE_ALT2_VENDOR := GWBN
  DEVICE_ALT2_MODEL := GW3001
  DEVICE_ALT3_VENDOR := GLC
  DEVICE_ALT3_MODEL := W7
  DEVICE_ALT4_VENDOR := netis
  DEVICE_ALT4_MODEL := MEX605
  DEVICE_DTS := mt7981b-netis-nx30v2
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTC_FLAGS := --pad 4096
  DEVICE_DTS_LOADADDR := 0x43f00000
  DEVICE_PACKAGES := 
  KERNEL_LOADADDR := 0x44000000
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_INITRAMFS_SUFFIX := .itb
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE_SIZE := 117248k
  IMAGE/sysupgrade.itb := append-kernel | fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-with-rootfs | pad-rootfs | append-metadata
  ARTIFACTS := spim-nand-preloader.bin spim-nand-bl31-uboot.fip
  ARTIFACT/spim-nand-preloader.bin	:= mt7981-bl2 spim-nand-ddr3
  ARTIFACT/spim-nand-bl31-uboot.fip	:= mt7981-bl31-uboot netis_nx30v2
endef
TARGET_DEVICES += netis_nx30v2

define Device/netis_nx32u
  DEVICE_VENDOR := netis
  DEVICE_MODEL := NX32U
  DEVICE_DTS := mt7981b-netis-nx32u
  DEVICE_DTS_DIR := ../dts
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	append-metadata
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware \
	kmod-usb3 kmod-usb-ledtrig-usbport automount
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7981-bl2 spim-nand-ddr3
  ARTIFACT/bl31-uboot.fip := mt7981-bl31-uboot netis_nx32u
endef
TARGET_DEVICES += netis_nx32u

define Device/nradio_c8-668gl
  DEVICE_VENDOR := NRadio
  DEVICE_MODEL := C8-668GL
  DEVICE_DTS := mt7981b-nradio-c8-668gl
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES :=  \
	kmod-usb-serial-option kmod-usb-net-cdc-ether kmod-usb-net-qmi-wwan \
	kmod-usb3 automount
  IMAGE_SIZE := 131072k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata | check-size
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += nradio_c8-668gl

define Device/qihoo_360t7-common
  DEVICE_VENDOR := Qihoo
  DEVICE_DTS_DIR := ../dts
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | \
	pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	append-metadata
  ARTIFACTS := bl31-uboot.fip preloader.bin
endef

define Device/qihoo_360t7-ubi
  DEVICE_MODEL := 360T7 (UBI)
  DEVICE_DTS := mt7981b-qihoo-360t7-ubi
  $(call Device/qihoo_360t7-common)
  ARTIFACT/bl31-uboot.fip := mt7981-bl31-uboot qihoo_360t7-ubi
  ARTIFACT/preloader.bin  := mt7981-bl2 spim-nand-ubi-ddr3-1866
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += qihoo_360t7-ubi

define Device/routerich_be7200
  DEVICE_VENDOR := Routerich
  DEVICE_MODEL := BE7200
  DEVICE_DTS := mt7987a-routerich-be7200
  DEVICE_DTS_DIR := ../dts
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL_LOADADDR := 0x40000000
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | \
	pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-with-rootfs | \
	pad-rootfs | append-metadata
  DEVICE_PACKAGES := mt7987-2p5g-phy-firmware kmod-mt7992-firmware \
	 kmod-regulator-userspace-consumer kmod-usb3 automount
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7987-bl2 spim-nand0
  ARTIFACT/bl31-uboot.fip := mt7987-bl31-uboot routerich_be7200
endef
ifeq ($(KERNEL_PATCHVER),6.12)
TARGET_DEVICES += routerich_be7200
endif

define Device/snr_snr-cpe-ax2
  DEVICE_VENDOR := SNR
  DEVICE_MODEL := SNR-CPE-AX2
  DEVICE_DTS := mt7981b-snr-snr-cpe-ax2
  DEVICE_DTS_DIR := ../dts
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	append-metadata
  DEVICE_PACKAGES := 
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7981-bl2 spim-nand-ddr3
  ARTIFACT/bl31-uboot.fip := mt7981-bl31-uboot snr_snr-cpe-ax2
endef
TARGET_DEVICES += snr_snr-cpe-ax2

define Device/teltonika_rutc50
  DEVICE_VENDOR := Teltonika
  DEVICE_MODEL := RUTC50
  SUPPORTED_TELTONIKA_DEVICES := teltonika,rutc
  DEVICE_DTS := mt7981a-teltonika-rutc50
  DEVICE_DTS_DIR := ../dts
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBINIZE_OPTS := -E 5
  DEVICE_PACKAGES :=    kmod-usb3 kmod-usb-net-qmi-wwan \
	kmod-usb-serial-option kmod-gpio-nxp-74hc164 uqmi automount
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | append-teltonika-metadata
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += teltonika_rutc50

define Device/tenbay_wr3000k
  DEVICE_VENDOR := Tenbay
  DEVICE_MODEL := WR3000K
  DEVICE_DTS := mt7981b-tenbay-wr3000k
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := 
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 49152k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL = kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS = kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += tenbay_wr3000k

define Device/teralink_tl3020-256mb
  DEVICE_VENDOR := Teralink
  DEVICE_MODEL := TL3020
  DEVICE_VARIANT := 256mb
  DEVICE_DTS := mt7981b-teralink-tl3020-256mb
  DEVICE_DTS_DIR := ../dts
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL := kernel-bin | libdeflate-gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	append-metadata
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7981-bl2 spim-nand-ddr3-1866
  ARTIFACT/bl31-uboot.fip := mt7981-bl31-uboot teralink_tl3020-256mb
endef
TARGET_DEVICES += teralink_tl3020-256mb

define Device/tplink_archer-ax80-v1-eu
  DEVICE_VENDOR := TP-Link
  DEVICE_MODEL := Archer AX80
  DEVICE_VARIANT := v1 (EU)
  DEVICE_DTS := mt7986b-tplink-archer-ax80-v1-eu
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7986-firmware mt7986-wo-firmware automount
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 51200k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += tplink_archer-ax80-v1-eu

define Device/tplink_be450
  DEVICE_VENDOR := TP-Link
  DEVICE_MODEL := BE450
  DEVICE_DTS := mt7988d-tplink-be450
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7992-firmware kmod-usb3 automount \
	    mt7988-2p5g-phy-firmware mt7988-wo-firmware
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 51200k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += tplink_be450

define Device/tplink_eap683-lr
  DEVICE_VENDOR := TP-Link
  DEVICE_MODEL := EAP683-LR
  DEVICE_ALT0_VENDOR := TP-Link
  DEVICE_ALT0_MODEL := EAP683-UR
  DEVICE_DTS := mt7986a-tplink-eap683-lr
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7986-firmware mt7986-wo-firmware
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 39424k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += tplink_eap683-lr

define Device/tplink_f65-v1
  DEVICE_VENDOR := TP-Link
  DEVICE_MODEL := F65
  DEVICE_VARIANT := v1
  DEVICE_DTS := mt7981b-tplink-f65v1
  DEVICE_DTS_DIR := ../dts
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += tplink_f65-v1

define Device/tplink_fr365-v1
  DEVICE_VENDOR := TP-Link
  DEVICE_MODEL := FR365
  DEVICE_VARIANT := v1
  DEVICE_DTS := mt7981b-tplink-fr365v1
  DEVICE_DTS_DIR := ../dts
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 32768k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/factory.ubi := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES := fitblk kmod-sfp kmod-usb3 automount
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += tplink_fr365-v1

define Device/wavlink_wl-wn551x3
  DEVICE_VENDOR := WAVLINK
  DEVICE_MODEL := WL-WN551X3
  DEVICE_DTS := mt7981b-wavlink-wl-wn551x3
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTS_LOADADDR := 0x47000000
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 65536k
  KERNEL_INITRAMFS_SUFFIX := .itb
  KERNEL_IN_UBI := 1
  DEVICE_PACKAGES := kmod-usb3  automount
  SUPPORTED_DEVICES += mediatek,mt7981-spim-snand-rfb
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += wavlink_wl-wn551x3

define Device/wavlink_wl-wn586x3b
  DEVICE_VENDOR := WAVLINK
  DEVICE_MODEL := WL-WN586X3B
  DEVICE_DTS := mt7981b-wavlink-wl-wn586x3b
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTS_LOADADDR := 0x47000000
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 65536k
  KERNEL_INITRAMFS_SUFFIX := .itb
  KERNEL_IN_UBI := 1
  DEVICE_PACKAGES := 
  IMAGES := factory.bin initramfs-kernel.bin sysupgrade.bin
  IMAGE/factory.bin := append-ubi | check-size $$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += wavlink_wl-wn586x3b

define Device/wavlink_wl-wnt100x3
  DEVICE_VENDOR := WAVLINK
  DEVICE_MODEL := WL-WNT100X3
  DEVICE_DTS := mt7981b-wavlink-wl-wnt100x3
  DEVICE_DTS_DIR := ../dts
  IMAGE_SIZE := 65536k
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7981-firmware \
  	mt7981-wo-firmware kmod-hwmon-pwmfan
  SUPPORTED_DEVICES += mediatek,mt7981-spim-snand-rfb
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += wavlink_wl-wnt100x3

define Device/wavlink_wl-wnt100x3-ubootmod
  DEVICE_VENDOR := WAVLINK
  DEVICE_MODEL := WL-WNT100X3
  DEVICE_VARIANT := (OpenWrt U-Boot layout)
  DEVICE_DTS := mt7981b-wavlink-wl-wnt100x3-ubootmod
  DEVICE_DTS_DIR := ../dts
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	append-metadata
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7981-firmware \
  	mt7981-wo-firmware kmod-hwmon-pwmfan
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7981-bl2 spim-nand-ddr3
  ARTIFACT/bl31-uboot.fip := mt7981-bl31-uboot wavlink_wl-wnt100x3
endef
TARGET_DEVICES += wavlink_wl-wnt100x3-ubootmod

define Device/widelantech_wap430x
  DEVICE_VENDOR := Widelantech
  DEVICE_MODEL := WAP430X
  DEVICE_ALT1_VENDOR := Widelantech
  DEVICE_ALT1_MODEL := AX3000AM
  DEVICE_ALT1_VENDOR := UeeVii
  DEVICE_ALT1_MODEL := UAP200
  DEVICE_DTS := mt7981b-widelantech-wap430x
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := 
  IMAGE_SIZE := 14784k
  SUPPORTED_DEVICES += UAP200 AX3000AM # allow upgrade via GECOOS UART menu
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += widelantech_wap430x

define Device/zbtlink_zbt-z8106ax-s
  DEVICE_VENDOR := Zbtlink
  DEVICE_MODEL := ZBT-Z8106AX-S
  SUPPORTED_DEVICES += zbtlink,z8106ax-2sim
  DEVICE_DTS := mt7981b-zbtlink-zbt-z8106ax-s
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware \
	kmod-usb3 kmod-usb-net-qmi-wwan kmod-usb-serial-option automount
  KERNEL_IN_UBI := 1
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 65536k
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | check-size $$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += zbtlink_zbt-z8106ax-s

define Device/zbtlink_zbt-z8106ax-t
  DEVICE_VENDOR := Zbtlink
  DEVICE_MODEL := ZBT-Z8106AX-T
  DEVICE_ALT0_VENDOR := Zbtlink
  DEVICE_ALT0_MODEL := ZBT-Z8106AX-M2-T
  SUPPORTED_DEVICES += zbtlink,z8106ax-2sim
  DEVICE_DTS := mt7981b-zbtlink-zbt-z8106ax-t
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware \
	kmod-usb3 kmod-usb-net-qmi-wwan kmod-usb-serial-option automount
  KERNEL_IN_UBI := 1
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 65536k
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | check-size $$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGES := sysupgrade.itb sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += zbtlink_zbt-z8106ax-t

define Device/zyxel_wx5600-t0-ubootmod
  DEVICE_VENDOR := Zyxel
  DEVICE_MODEL := WX5600-T0
  DEVICE_VARIANT := (OpenWrt U-Boot layout)
  DEVICE_DTS := mt7986b-zyxel-wx5600-t0-ubootmod
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7986-firmware mt7986-wo-firmware
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES :=  sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  BLOCKSIZE := 256k
  PAGESIZE := 4096
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  KERNEL := kernel-bin | lzma
  KERNEL_INITRAMFS := kernel-bin | lzma | \
        fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd
  IMAGE/sysupgrade.itb := append-kernel | \
        fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7986-bl2 spim-nand-4k-ddr3
  ARTIFACT/bl31-uboot.fip := mt7986-bl31-uboot zyxel_wx5600-t0
ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)
  ARTIFACTS += initramfs-factory.ubi
  ARTIFACT/initramfs-factory.ubi := append-image-stage initramfs-recovery.itb | ubinize-kernel
endif
endef
TARGET_DEVICES += zyxel_wx5600-t0-ubootmod
