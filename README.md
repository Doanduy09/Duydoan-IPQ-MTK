# Duydoan ImmortalWrt 24.10 LTS & 25.12 Multi-Platform CI/CD Firmware Suite

<div align="center">

[![Distro Version](https://img.shields.io/badge/Duydoan-24.10%20LTS%20%26%2025.12-007ec6.svg?style=for-the-badge&logo=openwrt)](https://github.com/Doanduy09/Duydoan-IPQ-MTK)
[![Qualcomm NSS](https://img.shields.io/badge/Qualcomm-NSS%2012.5%20Hardware%20Max-brightgreen.svg?style=for-the-badge&logo=qualcomm)](https://github.com/Doanduy09/Duydoan-IPQ-MTK)
[![MediaTek HNAT](https://img.shields.io/badge/MediaTek-Dual--PPE%20%2B%20WED%20HNAT%20Max-ff69b4.svg?style=for-the-badge)](https://github.com/Doanduy09/Duydoan-IPQ-MTK)
[![Multi-Build](https://img.shields.io/badge/Multi--Target-129%20Devices%20Unified-purple.svg?style=for-the-badge&logo=githubactions)](https://github.com/Doanduy09/Duydoan-IPQ-MTK/actions)
[![Maintained By](https://img.shields.io/badge/Author-Doanduy09-blue.svg?style=for-the-badge&logo=github)](https://github.com/Doanduy09)

**Hệ thống biên dịch Multi-Target CI/CD (kế thừa kiến trúc VIKINGYFY & tối ưu hóa kịch trần phần cứng cho Qualcomm NSS / MediaTek HNAT + Trình Quay Số 5G Thông Minh vượt trội QModem).**  
*Được duy trì và phát triển bởi Anh Duy (DOANDUY).*

</div>

---

## 🚀 ĐỒNG NHẤT 100% KERNEL MODULES (KMOD) & TRÌNH QUAY SỐ 5G TOÀN DIỆN

Mọi thiết bị thuộc các nhóm kiến trúc bên dưới đều được biên dịch **cùng 1 lần (Multi-Target Unified Build)** với bộ nhân và gói mở rộng đồng nhất 100%:
* **Trình Quay Số `WWAN Smart Dialer` & `Bác Sĩ 5G Watchdog`**:
  * Phân tách chính xác `l3_device` (VD: `eth2` của Fibocom FM350-GL) để ping/giám sát traffic và `interface` (`wwan0`) để `ifup`/`renew` IP qua `ubus`.
  * **Zero-Delay Interface Guard**: Tự động phát hiện và bật lại ngay lập tức nếu giao diện bị dừng/tắt trên LuCI hoặc rớt netifd.
  * **Tự động lấy lại IP sau 24h**: Chủ động tái kích hoạt PDP Context (`AT+CGACT=0,1` / `1,1`) và renew IP khi nhà mạng thu hồi IP sau 24h + lịch **Proactive Renewal 04:15 AM** mỗi ngày.
  * **Hỗ trợ mọi chuẩn kết nối Modem & Điện thoại**: PCIe MHI (`mtk_t7xx`, `mhi_pci`, `mhi_wwan_mbim`), USB (`qmi_wwan`, `qmi_wwan_fibocom`, `cdc_mbim`, `cdc_ncm`, `cdc_ether`, `rndis_host`, `ipheeth` iPhone).
* **Tăng Tốc Phần Cứng & Mạng**: `kmod-tcp-bbr`, `kmod-cryptodev`, `kmod-tls`, `kmod-nft-offload`, MediaTek Dual-PPE HNAT + WED hoặc Qualcomm NSS 12.5, tự động ghim **TTL 65 / HopLimit 65**.
* **LuCI Quản Trị Hợp Nhất (`/cgi-bin/luci/admin/modem/control`)**: Đọc/gửi SMS 2 chiều, tự dò cổng AT chuẩn xác (`ATI`), đổi IMEI, khóa băng tần 5G/4G, 1-Click Auto Mesh `802.11k/v/r` & Telegram AI Sentinel.

---

## 📌 DANH MỤC CHI TIẾT CÁC THIẾT BỊ ĐƯỢC HỖ TRỢ (MULTI-BUILD THEO KIẾN TRÚC)

### 🔹 NHÓM 1: MEDIATEK FILOGIC 880 / 830 / 820 (Config: `mediatek_filogic_all.config`)
Biên dịch đồng loạt trong workflow `Duydoan-25.12 MediaTek Filogic All-Devices Multi-Target Build` (cùng 1 kernel & bộ `kmod` đồng nhất):

#### 1.1. Dòng Flagship Wi-Fi 7 — MediaTek Filogic 880 (MT7988A - 4x Cortex-A73 1.8GHz)
| Thiết Bị (Profile ID) | RAM / Flash | Cổng Mạng | Wi-Fi & Cổng Mở Rộng |
| :--- | :--- | :--- | :--- |
| **TP-Link TL-7DR7230 v1 / v2** | 512MB / 128MB NAND | 1x 2.5G + 3x 1G (hoặc 4x 1G) | Wi-Fi 7 BE7200 (MLO, 320MHz/160MHz), HNAT 10Gbps |
| **TP-Link TL-7DR7250 v1** | 512MB / 128MB NAND | 1x 2.5G + 4x 1G | Wi-Fi 7 BE7200, Tản nhiệt lớn hiệu năng cao |

#### 1.2. Dòng Cao Cấp Wi-Fi 6/7 — MediaTek Filogic 830 (MT7986A - 4x Cortex-A53 2.0GHz)
| Thiết Bị (Profile ID) | RAM / Flash | Cổng Mạng | Wi-Fi & Cổng Mở Rộng |
| :--- | :--- | :--- | :--- |
| **ASUS TUF Gaming AX6000** | 512MB / 256MB NAND | 2x 2.5G + 4x 1G | Wi-Fi 6 AX6000 (4T4R 160MHz), 1x USB 3.0 Modem 5G |
| **ASUS TUF Gaming AX4200 / AX4200Q** | 512MB / 256MB NAND | 1x 2.5G + 4x 1G | Wi-Fi 6 AX4200 (4T4R 5G + 2T2R 2.4G), 1x USB 3.0 Modem 5G |
| **GL.iNet Flint 2 (`glinet_gl-mt6000`)** | 1GB DDR4 / 8GB eMMC | 2x 2.5G + 4x 1G | Wi-Fi 6 AX6000, 1x USB 3.0, eMMC siêu lớn |
| **Xiaomi / Redmi AX6000 (`stock` & `ubootmod`)** | 512MB / 128MB NAND | 1x 1G WAN + 3x 1G LAN | Wi-Fi 6 AX6000 (4T4R 160MHz), Dual-PPE HNAT |
| **TP-Link TL-XDR4288** | 512MB / 128MB NAND | 1x 2.5G + 1x SFP + 4x 1G | Wi-Fi 6 AX4200, Cổng quang SFP 2.5G |
| **TP-Link TL-XDR6086 / TL-XDR6088** | 512MB / 128MB NAND | 2x 2.5G (+ SFP) + 4x 1G | Wi-Fi 6 AX6000, 1x USB 3.0 Modem 5G |
| **TP-Link TL-XTR8488** | 512MB / 128MB NAND | 1x 2.5G + 1x SFP + 4x 1G | Tri-Band Wi-Fi 6 AX8400 (2.4G + 5G-1 + 5G-2) |
| **JDCloud Baizhang (`jdcloud_re-cp-03`)** | 1GB DDR4 / 128GB eMMC | 1x 2.5G + 3x 1G | Wi-Fi 6 AX6000, eMMC 128GB, 1x USB 3.0 |
| **Netcore N60 / N60-Pro** | 512MB / 128MB NAND | 1x (hoặc 2x) 2.5G + 3x 1G | Wi-Fi 6 AX6000, 1x USB 3.0 (bản Pro) |
| **Ruijie RG-X60 / RG-X60-Pro** | 512MB / 128MB NAND | 1x 2.5G + 3x 1G | Wi-Fi 6 AX6000, Thiết kế 8 anten ngoài |
| **Zyxel EX5700 Telenor** | 512MB / 128MB NAND | 2x 2.5G + 4x 1G | Wi-Fi 6 AX6000, 1x USB 3.0 |

#### 1.3. Dòng Phổ Thông & 5G CPE — MediaTek Filogic 820 (MT7981B - 2x Cortex-A53 1.3GHz)
| Thiết Bị (Profile ID) | RAM / Flash | Cổng Mạng | Wi-Fi & Tính Năng 4G/5G |
| :--- | :--- | :--- | :--- |
| **WirelessTag ZX7981PD** | 512MB / 128MB NAND | 2x 1G / 2.5G | **5G CPE Chuyên Dụng**: Khe M.2 PCIe Fibocom FM350-GL + Khe SIM + USB 3.0 + GPIO Power |
| **GL.iNet Spitz AX (`glinet_gl-x3000`)** | 512MB / 8GB eMMC | 1x 2.5G + 1x 1G | **5G CPE Flagship**: Khe M.2 5G + Dual-SIM + USB 3.0 + Khe thẻ TF |
| **GL.iNet Puli AX (`glinet_gl-xe3000`)** | 512MB / 8GB eMMC | 1x 2.5G + 1x 1G | **5G CPE Di Động**: Tích hợp Pin 6400mAh + M.2 5G + Dual-SIM |
| **GL.iNet Beryl AX (`glinet_gl-mt3000`)** | 512MB / 256MB NAND | 1x 2.5G + 1x 1G | Travel Router AX3000 nhỏ gọn + USB 3.0 cắm Modem 5G/iPhone |
| **GL.iNet Slate 7 (`glinet_gl-mt3600be`)** | 512MB / 512MB NAND | 2x 2.5G | Travel Router Wi-Fi 7 BE3600 + USB 3.0 |
| **ASUS ZenWiFi BT8 (`stock` & `ubootmod`)** | MT7988D / 1GB / 128MB NAND | 2x 2.5G + 2x 1G + USB 3.0 | Tri-Band **Wi-Fi 7 BE14000** (MLO 2.4G+5G+6G, `mt7996e`) |
| **BananaPi BPi-R4 (`bananapi_bpi-r4`)** | MT7988A / 4GB-8GB DDR4 / NAND+eMMC | **2x 10G SFP+ + 4x 1G + M.2 5G + USB 3.2** | Flagship **Wi-Fi 7 BE14000** (`mt7996e`), Dual-PPE 10Gbps |
| **BananaPi BPi-R4 PoE (`bananapi_bpi-r4-poe`)** | MT7988A / 4GB DDR4 / NAND+eMMC | **2x 10G SFP+ + 4x 2.5GbE PoE + M.2 5G** | Flagship **Wi-Fi 7 BE14000** + 2.5G PHY |
| **BananaPi BPi-R4 Lite (`bananapi_bpi-r4-lite`)** | MT7987A / 2GB DDR4 / NAND+eMMC | **1x 2.5G SFP + 1x 2.5G + 3x 1G + M.2 5G** | **Wi-Fi 7** (`mt7992e`) + M.2 WWAN 5G |
| **TP-Link Archer BE450 (`tplink_be450`)** | MT7988D / 512MB / 128MB NAND | 1x 10G + 1x 2.5G + 3x 1G + USB 3.0 | **Wi-Fi 7 BE7200** (MLO), HNAT 10Gbps |
| **Routerich BE7200 (`routerich_be7200`)** | MT7987A / 512MB / 128MB NAND | 2x 2.5G + 3x 1G + USB 3.0 | **Wi-Fi 7 BE7200** (`mt7992e`), 2.5G PHY |
| **Hiveton H5000M (`hiveton_h5000m`)** | MT7987A / 1GB / 128MB NAND | **2.5GbE + Khe M.2 5G + USB 3.0** | **5G CPE Wi-Fi 7 BE7200** (`mt7992e`), Quáº¡t PWM |
| **Arcadyan Mozart (`arcadyan_mozart`)** | MT7988A / 2GB / 4GB eMMC | **2x 10GbE + 4x 1GbE** | Flagship **Wi-Fi 7 Tri-Band** (`mt7996e`) |
| **SmartRG SDG-8733 / 8733A / 8734** | MT7988A/D / 1GB-2GB / 8GB eMMC | **1x 10GbE + 4x 2.5GbE + USB 3.0** | Carrier-Grade **Wi-Fi 7 Tri-Band** (`mt7996e`) |
| **Keenetic Titan KN-1812 / Netcraze NC-1812** | MT7988D / 1GB / 512MB NAND | **1x 10G + 1x 2.5G + 4x 1G + 2x USB 3.2** | **Wi-Fi 7 BE7200** + Dual USB 3.2 Modem 5G |
| **CMCC RAX3000M / RAX3000ME (NAND & eMMC)** | 512MB / 128MB NAND hoặc 64GB eMMC | 1x 1G WAN + 3x 1G LAN | Wi-Fi 6 AX3000 (160MHz) + USB 3.0 Modem 5G |
| **Viettel NR3053 / SDMC MT3053** | 512MB / 128MB NAND | 1x 1G WAN + 3x 1G LAN | Wi-Fi 6 AX3000 (160MHz), hỗ trợ mod USB 3.0 5G |
| **Xiaomi AX3000T / WR30U (`stock` & `ubootmod`)** | 256MB / 128MB NAND | 4x 1G | Wi-Fi 6 AX3000 (160MHz), HNAT WED Turbo |
| **Cudy TR3000 v1 (`stock` & `ubootmod`)** | 512MB / 128MB NAND | 1x 2.5G + 1x 1G | Travel Router AX3000 + USB 3.0 Modem 5G |
| **Qihoo 360T7 / 360T7-UBI** | 256MB / 128MB NAND | 4x 1G | Wi-Fi 6 AX3000 (160MHz) |
| **Huasifei WH3000 / WH3000-Pro (`emmc` & `nand`)** | 512MB / eMMC hoặc NAND | 1x 2.5G + 3x 1G | Wi-Fi 6 AX3000 + USB 3.0 / M.2 Modem 5G |
| **ZBTLink Z8102AX / Z8103AX / Z8106AX (Các biến thể)** | 512MB / 128MB NAND | 1x 2.5G + 3x 1G | Chuyên dụng 5G CPE (Khe M.2 5G + USB 3.0 + Dual-SIM) |
| **ABT ASR3000 / AirPi AP3000M / JCG Q30-Pro** | 256-512MB / 128MB NAND | 4x 1G | Wi-Fi 6 AX3000 (160MHz) |
| **Cetron CT3003 / CMCC A10 / Comfast CF-E393AX / CF-WR632AX** | 256-512MB / 128MB NAND | 4x 1G / PoE | Wi-Fi 6 AX3000 Router / AP |
| **Creatlentem CLT-R30B1 / Globitel BT-R320 / Imou HX21 / Konka KOMI-A31 / Nokia EA0326GMP** | 256-512MB / 128MB NAND | 4x 1G | Wi-Fi 6 AX3000 (160MHz) |

---

### 🔹 NHÓM 2: QUALCOMM IPQ60XX + NSS 12.5 HARDWARE OFFLOAD (Config: `qualcomm_ipq60xx_all.config`)
Biên dịch đồng loạt trong workflow `Duydoan-25.12 Qualcomm IPQ60xx All-Devices Multi-Target Build` (10 thiết bị):

| Thiết Bị (Profile ID) | SoC / RAM / Flash | Cổng Mạng & Mở Rộng | Wi-Fi & NSS Hardware Offload |
| :--- | :--- | :--- | :--- |
| **JDCloud Athena (`jdcloud_re-cs-02`)** | IPQ6010 (4x 1.2GHz) / 1GB DDR4 / **128GB eMMC F2FS** | 1x 2.5G + 4x 1G + **M.2 5G** + LED Ma Trận | Tri-Band AX6600 (`ath11k`), **Qualcomm NSS 12.5 Max** |
| **GL.iNet Flint (`glinet_gl-ax1800`)** | IPQ6000 (4x 1.2GHz) / 512MB / 128MB NAND | 5x 1G + 1x USB 3.0 Modem 5G | Dual-Band AX1800, **Qualcomm NSS 12.5 Max** |
| **GL.iNet Slate AX (`glinet_gl-axt1800`)** | IPQ6000 (4x 1.2GHz) / 512MB / 128MB NAND | 3x 1G + 1x USB 3.0 + Khe TF | Dual-Band AX1800, **Qualcomm NSS 12.5 Max** |
| **Qihoo 360 V6 (`qihoo_360v6`)** | IPQ6000 (4x 1.2GHz) / 512MB / 128MB NAND | 4x 1G + 1x USB 3.0 Modem 5G | Dual-Band AX1800, **Qualcomm NSS 12.5 Max** |
| **Linksys MR7350 (`linksys_mr7350`)** | IPQ6000 (4x 1.2GHz) / 512MB / 256MB NAND | 5x 1G + 1x USB 3.0 Modem 5G | Dual-Band AX1800, **Qualcomm NSS 12.5 Max** |
| **Linksys MR7500 (`linksys_mr7500`)** | IPQ6018 (4x 1.8GHz) / 512MB / 256MB NAND | 1x 2.5G + 4x 1G + 1x USB 3.0 | Tri-Band AXE6600 Wi-Fi 6E, **Qualcomm NSS 12.5 Max** |
| **Netgear WAX214 / WAX610 / WAX610Y** | IPQ6010 / 512MB / 256MB NAND | 1x 2.5G PoE+ (WAX610) | Access Point Wi-Fi 6 AX1800 Doanh Nghiệp |
| **Yuncore FAP650 (`yuncore_fap650`)** | IPQ6010 / 512MB / 128MB NAND | 1x 2.5G + 1x 1G PoE | Access Point Wi-Fi 6 AX1800 Công Suất Cao |

---

### 🔹 NHÓM 3: QUALCOMM IPQ807X + NSS 12.5 HARDWARE OFFLOAD (Config: `qualcomm_ipq807x_all.config`)
Biên dịch đồng loạt trong workflow `Duydoan-25.12 Qualcomm IPQ807x All-Devices Multi-Target Build` (19 thiết bị):

| Thiết Bị (Profile ID) | SoC / RAM / Flash | Cổng Mạng & Mở Rộng 5G | Wi-Fi & NSS Hardware Offload |
| :--- | :--- | :--- | :--- |
| **Swaiot S10-SKY (`swaiot_s10sky`)** | IPQ8071/8074 / 1GB DDR4 / 16MB NOR + 256MB NAND | **1x 2.5G + 2x 1G + M.2 PCIe 5G + 2x USB 3.0** | Dual-Band AX (`ath11k`), **NSS 12.5 Max**, Chuyên trị FM350-GL / SDX55 |
| **Xiaomi AX9000 (`stock` & `ubootmod`)** | IPQ8072A (4x 2.2GHz) / 1GB / 256MB NAND | 1x 2.5G + 4x 1G + 1x USB 3.0 Modem 5G | Tri-Band **AX9000** Gaming + AIoT, **NSS 12.5 Max** |
| **Xiaomi AX3600 (`stock` & `ubootmod`)** | IPQ8071A (4x 1.4GHz) / 512MB / 256MB NAND | 4x 1G | Dual-Band AX3000 + AIoT Antenna, **NSS 12.5 Max** |
| **Redmi AX6 (`stock` & `ubootmod`)** | IPQ8071A (4x 1.4GHz) / 512MB / 128MB NAND | 4x 1G | Dual-Band AX3000, **NSS 12.5 Max** |
| **QNAP QHora-301W (`qnap_301w`)** | IPQ8072A (4x 2.2GHz) / 1GB / 4GB eMMC | **2x 10GbE + 4x 1GbE + 2x USB 3.2** | Dual-Band AX3600, **NSS 12.5 Max (10Gbps Routing)** |
| **Arcadyan AW1000 (`arcadyan_aw1000`)** | IPQ8072A / 1GB / 512MB NAND | **1x 2.5G + 4x 1G + Khe M.2 5G + Khe SIM** | **5G CPE Cao Cấp**, Wi-Fi 6 AX3600, **NSS 12.5 Max** |
| **TP-Link Deco X80-5G (`tplink_deco-x80-5g`)** | IPQ8072A / 1GB / 256MB NAND | **1x 2.5G + 1x 1G + Modem 5G tích hợp** | **5G Mesh CPE**, Wi-Fi 6 AX5400, **NSS 12.5 Max** |
| **ZTE MF269 (`stock` & `ubootmod`)** | IPQ807x / 512MB / 256MB NAND | Cổng LAN/WAN + Khe SIM 4G/5G | **CPE Di Động**, Wi-Fi 6 AX3000, **NSS 12.5 Max** |
| **Dynalink DL-WRX36 (`dynalink_dl-wrx36`)** | IPQ8072A (4x 2.2GHz) / 1GB / 256MB NAND | 1x 2.5G + 4x 1G + 1x USB 3.0 Modem 5G | Dual-Band AX3600, **NSS 12.5 Max** |
| **Linksys Velop MX (`mx4200v1`, `v2`, `mx4300`, `mx5300`, `mx8500`)** | IPQ8072A/8074 / 512MB-1GB / 256-512MB NAND | 4x-5x 1G (2.5G trên MX8500) + USB 3.0 | Tri-Band Mesh Wi-Fi 6 (AX4200–AX5300), **NSS 12.5 Max** |
| **Aliyun AP8220 (`aliyun_ap8220`)** | IPQ8072A / 1GB / 128MB NAND | 2x 2.5G PoE | AP Doanh Nghiệp Wi-Fi 6 AX3600, **NSS 12.5 Max** |

---

## 🛠️ GIÁM SÁT & TỰ CHỮA LÀNH CI/CD 24/24
* **GitHub CI Sentinel Service (`github-ci-sentinel.service`)**: Chạy thường trực 24/24 trên máy ảo Debian độc lập, tự động theo dõi trạng thái biên dịch của toàn bộ các workflow trên GitHub Actions, phân tích log lỗi và tự khắc phục khi phát sinh sự cố.
