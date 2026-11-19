# Duydoan ImmortalWrt 24.10 LTS & 25.12 Multi-Platform CI/CD Firmware Suite

<div align="center">

[![Distro Version](https://img.shields.io/badge/Duydoan-24.10%20LTS%20%26%2025.12-007ec6.svg?style=for-the-badge&logo=openwrt)](https://github.com/Doanduy09/Duydoan-IPQ-MTK)
[![Qualcomm NSS](https://img.shields.io/badge/Qualcomm-NSS%2012.5%20Hardware%20Max-brightgreen.svg?style=for-the-badge&logo=qualcomm)](https://github.com/Doanduy09/Duydoan-IPQ-MTK)
[![MediaTek HNAT](https://img.shields.io/badge/MediaTek-Dual--PPE%20%2B%20WED%20HNAT%20Max-ff69b4.svg?style=for-the-badge)](https://github.com/Doanduy09/Duydoan-IPQ-MTK)
[![Crypto Accel](https://img.shields.io/badge/Crypto-SafeXcel%20EIP--97-orange.svg?style=for-the-badge)](https://github.com/Doanduy09/Duydoan-IPQ-MTK)
[![Daily Build](https://img.shields.io/badge/Auto%20Build-Daily%2006%3A00%20ICT-success.svg?style=for-the-badge&logo=githubactions)](https://github.com/Doanduy09/Duydoan-IPQ-MTK/actions)
[![Maintained By](https://img.shields.io/badge/Author-Doanduy09-blue.svg?style=for-the-badge&logo=github)](https://github.com/Doanduy09)

**Hệ thống biên dịch và phát hành firmware tự động tối ưu hóa kịch trần năng lực phần cứng cho các dòng Router cao cấp Qualcomm & MediaTek.**  
*Được duy trì và phát triển bởi Anh Duy (DOANDUY).*

</div>

---

## 📌 DANH MỤC THIẾT BỊ HỖ TRỢ CHÍNH THỨC (PHÂN THEO DÒNG CHIPSET)

### 🔹 NHÓM 1: MEDIATEK FILOGIC 830 (MT7986A - 4 NHÂN CORTEX-A53 2.0 GHz)

| Thiết Bị | Kiến Trúc Phần Cứng & Cấu Hình Chi Tiết | Tăng Tốc Phần Cứng & HNAT | Tính Năng Đặc Biệt |
| :--- | :--- | :--- | :--- |
| **ASUS TUF Gaming AX6000** | • **SoC**: MediaTek MT7986A Filogic 830 (4x 2.0 GHz)<br>• **RAM**: 512MB/1GB DDR3/DDR4<br>• **Flash**: 256MB SPI-NAND<br>• **Cổng mạng**: 2 Cổng 2.5Gbps WAN/LAN + 4 Cổng 1Gbps LAN<br>• **Wi-Fi 6**: 4T4R AX6000 (160MHz Dual MT7976GN)<br>• **USB**: 1 Cổng USB 3.0 cắm modem 5G / ổ cứng | **MediaTek Dual-PPE HNAT (32,768 luồng)**<br>+ mt7915e WED Turbo Direct DMA<br>+ SafeXcel EIP-97 Crypto Engine<br>+ **Công tắc HNAT 1-Click trên LuCI** | • Tốc độ định tuyến 2.5Gbps CPU ~0%<br>• Trọn bộ 5G Modem Manager & AT Commands<br>• 1-Click Auto Mesh 802.11k/v/r<br>• Giao diện Master Dashboard Chuyên Sâu |
| **ASUS TUF Gaming AX4200** | • **SoC**: MediaTek MT7986A Filogic 830 (4x 2.0 GHz)<br>• **RAM**: 512MB DDR3<br>• **Flash**: 256MB SPI-NAND<br>• **Cổng mạng**: 1 Cổng 2.5Gbps WAN/LAN + 4 Cổng 1Gbps LAN<br>• **Wi-Fi 6**: 4T4R 5GHz 160MHz + 2T2R 2.4GHz AX4200<br>• **USB**: 1 Cổng USB 3.0 cắm modem 5G / ổ cứng | **MediaTek Dual-PPE HNAT (32,768 luồng)**<br>+ mt7915e WED Turbo Direct DMA<br>+ SafeXcel EIP-97 Crypto Engine<br>+ **Công tắc HNAT 1-Click trên LuCI** | • Tốc độ định tuyến 2.5Gbps CPU ~0%<br>• Trọn bộ 5G Modem Manager & AT Commands<br>• 1-Click Auto Mesh 802.11k/v/r<br>• Giao diện Master Dashboard Chuyên Sâu |

---

### 🔹 NHÓM 2: MEDIATEK FILOGIC 820 (MT7981B - 2 NHÂN CORTEX-A53 1.3 GHz)

| Thiết Bị | Kiến Trúc Phần Cứng & Cấu Hình Chi Tiết | Tăng Tốc Phần Cứng & HNAT | Tính Năng Đặc Biệt |
| :--- | :--- | :--- | :--- |
| **CMCC RAX3000M (Bản eMMC)** | • **SoC**: MediaTek MT7981B Filogic 820 (2x 1.3 GHz)<br>• **RAM**: 512MB DDR4 tốc độ cao<br>• **Flash**: **4GB / 8GB eMMC** (Cài đặt app không giới hạn)<br>• **Cổng mạng**: 1 Cổng 1Gbps WAN + 3 Cổng 1Gbps LAN (1000Mbps Full Duplex)<br>• **Wi-Fi 6**: 2T2R AX3000 (2.4G 574M + 5G 2402M HE160)<br>• **USB**: 1 Cổng USB 3.0 cắm Modem 5G / ổ cứng di động | **MediaTek PPE v2 HNAT (WED Turbo)**<br>+ SafeXcel EIP-97 Crypto Engine<br>+ HNAT Hardware Flow Offload | • Bộ nhớ eMMC dung lượng lớn, hỗ trợ Docker / cài gói thoải mái<br>• Bộ công cụ 4G/5G chuyên sâu (Quectel, Fibocom, MBIM, QMI)<br>• Hỗ trợ GPT, Preloader & U-Boot FIP riêng biệt |
| **CMCC RAX3000M (Bản SPI-NAND)** | • **SoC**: MediaTek MT7981B Filogic 820 (2x 1.3 GHz)<br>• **RAM**: 512MB DDR4 tốc độ cao<br>• **Flash**: **128MB SPI-NAND Flash**<br>• **Cổng mạng**: 1 Cổng 1Gbps WAN + 3 Cổng 1Gbps LAN (1000Mbps Full Duplex)<br>• **Wi-Fi 6**: 2T2R AX3000 (2.4G 574M + 5G 2402M HE160)<br>• **USB**: 1 Cổng USB 3.0 cắm Modem 5G / ổ cứng di động | **MediaTek PPE v2 HNAT (WED Turbo)**<br>+ SafeXcel EIP-97 Crypto Engine<br>+ HNAT Hardware Flow Offload | • Phiên bản tối ưu cho flash SPI-NAND 128MB<br>• Tích hợp EasyMesh, Batman-adv, DAWN Roaming, ModemInfo<br>• Hỗ trợ Preloader & U-Boot FIP NAND riêng biệt |
| **WirelessTag ZX7981PD** | • **SoC**: MediaTek MT7981B Filogic 820 (2x 1.3 GHz)<br>• **RAM**: **1GB DDR4** tốc độ cao<br>• **Flash**: **128MB SPI-NAND Flash**<br>• **Cổng mạng**: 1 Cổng 1Gbps WAN + 2 Cổng 1Gbps LAN (MediaTek MT7531 Switch)<br>• **Wi-Fi 6**: 2T2R AX3000 (MediaTek MT7915E, 2.4G 574M + 5G 2402M HE160)<br>• **Khe cắm M.2 Key-B 5G**: PCIe & USB 3.0 chuyên dụng (Fibocom FM350-GL, Quectel RM500Q/RM520N, Sierra EM919x)<br>• **SIM**: Khe Dual Nano-SIM chuyển đổi thông minh qua GPIO 25<br>• **Reset Modem**: GPIO 2 điều khiển Power/Reset | **MediaTek PPE v2 HNAT (WED Turbo)**<br>+ SafeXcel EIP-97 Crypto Engine<br>+ HNAT Hardware Flow Offload | • Thiết kế chuẩn 5G CPE chuyên nghiệp, tản nhiệt tốt<br>• Nhận diện tức thì card 5G PCIe Fibocom FM350-GL & Modem USB<br>• Tự động nhận diện SIM, khóa băng tần 5G/4G, đổi TTL 65 né bóp dung lượng<br>• Tích hợp lệnh CLI `ati` độc quyền & Web LuCI Tiện Ích 5G & Modem<br>• Tự động quay số `modem_autodial.sh` khi khởi động Router |
| **Viettel NR3053 / SDMC MT3053** | • **SoC**: MediaTek MT7981B Filogic 820 (2x 1.3 GHz)<br>• **RAM**: 512MB DDR3<br>• **Flash**: 128MB SPI-NAND<br>• **Cổng mạng**: 1 Cổng 1Gbps WAN + 3 Cổng 1Gbps LAN (1000Mbps Full Duplex)<br>• **Wi-Fi 6**: 2T2R AX3000 (2.4G 574M + 5G 2402M HE160)<br>• **USB**: Mod phần cứng USB 3.0 cắm Modem 5G ngoài | **MediaTek PPE v2 HNAT (WED Turbo)**<br>+ SafeXcel EIP-97 Crypto Engine<br>+ **Công tắc HNAT 1-Click trên LuCI** | • Tương thích 100% layout gốc SDMC factory.ubi và U-Boot FIP<br>• Hiệu chuẩn EEPROM sóng Wi-Fi chuẩn xác 100%<br>• Master Dashboard & 1-Click Auto Mesh |

---

### 🔹 NHÓM 3: QUALCOMM IPQ6010 / IPQ6000 (4 NHÂN CORTEX-A53 1.2 GHz + NPU NSS)

| Thiết Bị | Kiến Trúc Phần Cứng & Cấu Hình Chi Tiết | Tăng Tốc Phần Cứng & NSS | Tính Năng Đặc Biệt |
| :--- | :--- | :--- | :--- |
| **JDCloud Athena AX6600 (RE-CS-02)** | • **SoC**: Qualcomm IPQ6010 (4x 1.2 GHz)<br>• **RAM**: 1GB DDR4<br>• **Flash**: **128GB eMMC F2FS**<br>• **Cổng mạng**: 1 Cổng 2.5Gbps WAN/LAN + 4 Cổng 1Gbps LAN<br>• **Wi-Fi 6**: Tri-Band AX6600 (2.4G + 5.2G + 5.8G Qualcomm ath11k)<br>• **Mở rộng**: Khe cắm module WWAN M.2 5G Sierra/Quectel + LED ma trận | **Qualcomm NSS 12.5 Hardware Max**<br>+ ECM Flow Offload (NSS Core 0/1)<br>+ Qualcomm Crypto Acceleration | • eMMC 128GB F2FS siêu tốc cài đặt app không giới hạn<br>• Màn hình LED ma trận hiển thị đồng hồ thời gian & trạng thái mạng<br>• Hỗ trợ module WWAN 5G khe M.2 trong thân máy |

---

### 🔹 NHÓM 4: QUALCOMM IPQ8071 / IPQ8074 (4 NHÂN CORTEX-A53 + NPU NSS)

| Thiết Bị | Kiến Trúc Phần Cứng & Cấu Hình Chi Tiết | Giao Tiếp Mạng & Modem 5G | Tính Năng Đặc Biệt |
| :--- | :--- | :--- | :--- |
| **Swaiot S10-SKY** | • **SoC**: Qualcomm IPQ8071 / IPQ8074 (4x Cortex-A53 1.0-1.4 GHz + NSS NPU Engine)<br>• **RAM**: **1GB DDR4** 32-bit tốc độ cao (`ipq8074.dtsi`)<br>• **Flash**: Dual-Flash 16MB SPI-NOR (`n25q128a11`) + **256MB QPIC NAND** (phân vùng động U-Boot `rootfs` + `0:WIFIFW`)<br>• **Cổng mạng**: 1 Cổng **2.5Gbps WAN** (`dp5` QCA8081 SGMII PHY) + 2 Cổng **1Gbps LAN** (`dp4` `lan1`, `dp3` `lan2` QCA8075 Switch QSGMII)<br>• **Wi-Fi 6**: Dual-Band Qualcomm `ath11k` (2.4GHz + 5GHz AX, tự động trích xuất caldata từ `0:ART`)<br>• **Khe M.2 PCIe 5G**: `&pcie0` (perst GPIO 58, power GPIO 29/30/35) chuyên dụng cho card 5G PCIe tốc độ cao<br>• **USB 3.0**: 2 Cổng USB 3.0 DWC3 (`dwc3-qcom` `&usb_0` / `&usb_1`) | • **Hỗ trợ toàn diện Modem PCIe**: Driver kernel `mtk_t7xx` (Fibocom FM350-GL / MediaTek T700 MBIM qua `/dev/wwan0mbim0` & AT `/dev/wwan0at0`) + Qualcomm SDX55/SDX62/SDX65 MHI PCIe (`/dev/mhi_DUN`, `/dev/mhi_QMI0`)<br>• **Hỗ trợ Modem USB**: `qmi_wwan` (`uqmi`), `cdc_mbim` (`umbim`), `cdc_ncm`, `qmi_wwan_q/f/s`<br>• **Tự Động Quay Số Khi Đủ Điều Kiện (Auto-Dial Engine)**: Tích hợp `/usr/bin/modem_autodial.sh`, tự phát hiện card PCIe/USB, kiểm tra SIM READY, tự tra cứu ICCID để gán APN chuẩn mạng Viettel (`v-internet`), Vinaphone (`m3-world`), Mobifone (`m-i090`), Wintel và quay số ngay lập tức<br>• **Lệnh CLI `ati` Trực Tiếp Trong ROM**: Công cụ `/usr/bin/ati` (và `/bin/ati`) tự dò cổng AT (`/dev/wwan0at0`, `/dev/mhi_DUN`, `/dev/ttyUSB*`), hiển thị trọn vẹn thông tin modem (Model, IMEI, SIM, CSQ, Operator) và gửi lệnh AT tùy biến | • **Web LuCI Quản Trị Modem 5G (`admin/modem/control`)**: Hỗ trợ đầy đủ cổng AT PCIe `/dev/wwan0at0`, hiển thị danh sách cổng trực quan, đổi IMEI né bóp, khóa băng tần 5G/4G theo nhà mạng, đổi TTL 65 né phát Hotspot, đọc và gửi SMS 2 chiều<br>• **Bác Sĩ Mạng 5G Tự Chữa Lành 4 Tầng (`smart_modem_watchdog.sh`)**: Tự động phục hồi kết nối 24/7 không cần khởi động lại Router<br>• **Tương thích 100% U-Boot Sysupgrade**: Nâng cấp qua giao diện web hoặc terminal mượt mà |

---

## ⚡ CƠ CHẾ TĂNG TỐC PHẦN CỨNG MEDIATEK HNAT (PPE + WED TURBO)

Trên các dòng router MediaTek Filogic (ASUS TUF-AX6000, ASUS TUF-AX4200, CMCC RAX3000M, Viettel NR3053):
1. **MediaTek PPE (Packet Processing Engine)**:
   - Trang bị công cụ chuyển mạch gói phần cứng với năng lực xử lý lên tới **32,768 kết nối đồng thời**.
   - Gói tin mạng qua cổng 2.5Gbps được xử lý trực tiếp trên chip chuyển mạch phần cứng, đưa mức sử dụng CPU về mức **~0%** ngay cả khi kéo Full tải 2.5Gbps, giúp Router luôn mát mẻ và không bị nghẽn CPU.
2. **MediaTek WED (Wireless Ethernet Dispatcher) Turbo**:
   - Cầu nối DMA trực tiếp giữa chip chuyển mạch mạng và card Wi-Fi 6 `mt7915e`, loại bỏ hoàn toàn hiện tượng nghẽn cổ chai truyền dữ liệu qua RAM/CPU khi truyền tải tốc độ cao qua sóng không dây.
3. **Nút Bật / Tắt HNAT 1-Click Trực Tiếp Trên Dashboard**:
   - Tích hợp huy hiệu công tắc `[🟢 HNAT: BẬT]` / `[⚪ HNAT: TẮT]` ngay trên thanh trạng thái trang Tổng quan LuCI.
   - **Khi BẬT HNAT (`🟢 HNAT: BẬT`)**: Kích hoạt tối đa PPE HW + WED Turbo cho tốc độ tải cực đại, giảm nhiệt độ thiết bị.
   - **Khi TẮT HNAT (`⚪ HNAT: TẮT`)**: Chuyển sang định tuyến CPU thuần túy, tương thích hoàn hảo 100% với các tính năng can thiệp gói tin sâu như PassWall, Clash, SSR-Plus, Cake/SQM QoS và VPN định tuyến từng luồng.

---

## 📖 HƯỚNG DẪN NẠP FIRMWARE CHI TIẾT CHO TỪNG THIẾT BỊ

### 1. ASUS TUF Gaming AX6000 & ASUS TUF Gaming AX4200

#### Cách 1: Nạp từ Firmware gốc ASUSWRT (Lần đầu chuyển sang OpenWrt)
> **Khuyến nghị sử dụng chế độ ASUS Rescue Mode (Phục hồi phần mềm ASUS):**
1. Tải file firmware cài đặt dạng `*.trx` (hoặc `initramfs.trx` tương ứng với thiết bị) từ mục [Releases](https://github.com/Doanduy09/Duydoan-IPQ-MTK/releases).
2. Tải và cài đặt công cụ **ASUS Firmware Restoration Tool** từ trang chủ ASUS (hoặc chuẩn bị trình duyệt Web).
3. Đặt IP tĩnh cho cổng mạng LAN trên máy tính:
   - **IP Address**: `192.168.1.10`
   - **Subnet Mask**: `255.255.255.0`
   - **Default Gateway**: `192.168.1.1`
4. Rút tất cả các dây mạng trên router, chỉ cắm duy nhất 1 dây LAN nối từ máy tính vào **Cổng LAN 1** của Router ASUS TUF.
5. Rút nguồn điện của router. Nhấn và **giữ đè nút Reset**, sau đó cắm nguồn điện trở lại.
6. Tiếp tục giữ nút Reset khoảng 5-8 giây cho đến khi **đèn nguồn (Power LED) nhấp nháy chậm đều**, thả tay ra (Router đã vào ASUS Rescue Mode).
7. Mở phần mềm ASUS Firmware Restoration Tool (hoặc mở trình duyệt truy cập `http://192.168.1.1`), chọn file firmware `*.trx` và bấm **Upload**.
8. Đợi khoảng 3-5 phút cho router nạp firmware và khởi động lại. Chuyển card mạng máy tính về **DHCP tự động**, truy cập LuCI tại `http://192.168.1.1` (Tài khoản: `root`, không cần mật khẩu).

#### Cách 2: Nâng cấp từ OpenWrt / ImmortalWrt có sẵn (Sysupgrade)
1. Đăng nhập vào LuCI: Chọn menu **Hệ thống (System)** ➔ **Sao lưu / Nạp phần mềm (Backup / Flash Firmware)**.
2. Tại mục **Flash new firmware image**, bấm chọn file:
   - Đối với AX6000: `openwrt-mediatek-filogic-asus_tuf-ax6000-squashfs-sysupgrade.bin`
   - Đối với AX4200: `openwrt-mediatek-filogic-asus_tuf-ax4200-squashfs-sysupgrade.bin`
3. Bấm **Flash image...**, kiểm tra mã băm SHA256 và bấm **Tiếp tục (Continue)**. Đợi router nạp xong và tự khởi động lại.

---

### 2. CMCC RAX3000M (MediaTek MT7981B - Bản eMMC & Bản SPI-NAND)

#### Phân biệt 2 phiên bản phần cứng:
- **Bản eMMC**: Mặt đáy thiết bị ghi bộ nhớ 4GB hoặc 8GB eMMC, trên bo mạch tích hợp chip eMMC.
- **Bản NAND**: Mặt đáy thiết bị ghi bộ nhớ 128MB SPI-NAND.

#### Danh mục file nạp tương ứng cho từng bản:
- **Dành cho Bản eMMC**:
  - `*emmc-gpt.bin`: Bảng phân vùng GPT cho bộ nhớ eMMC.
  - `*emmc-preloader.bin`: Bootloader cấp 1 (BL2) cho eMMC.
  - `*emmc-bl31-uboot.fip`: U-Boot FIP (BL31 + U-Boot Web Failsafe).
  - `*cmcc_rax3000m-squashfs-sysupgrade.bin`: Firmware hệ thống (tự nhận diện eMMC qua DTB overlay).
- **Dành cho Bản NAND**:
  - `*nand-preloader.bin`: Bootloader cấp 1 (BL2) cho chip nhớ SPI-NAND.
  - `*nand-bl31-uboot.fip`: U-Boot FIP (BL31 + U-Boot Web Failsafe) cho SPI-NAND.
  - `*cmcc_rax3000m-squashfs-sysupgrade.bin`: Firmware hệ thống (tự nhận diện NAND qua DTB overlay).

#### Hướng dẫn nạp lần đầu từ Firmware gốc hoặc U-Boot Web Failsafe:
1. Đặt IP tĩnh máy tính: `192.168.1.10 / 255.255.255.0`. Cắm dây LAN vào cổng LAN của router.
2. Giữ nút **Reset** và cắm nguồn điện đến khi đèn LED nhấp nháy chuyển màu, truy cập `http://192.168.1.1` trên trình duyệt để vào Web U-Boot Failsafe.
3. Chọn file firmware `*cmcc_rax3000m-squashfs-sysupgrade.bin` và nạp.
4. Chờ 3 phút, router tự khởi động lại vào hệ điều hành ImmortalWrt.

#### Nâng cấp từ LuCI OpenWrt (Sysupgrade):
- Vào menu **Hệ thống (System)** ➔ **Sao lưu / Nạp phần mềm (Backup / Flash Firmware)**.
- Chọn file `*cmcc_rax3000m-squashfs-sysupgrade.bin` và bấm nạp trực tiếp.

---

### 3. Viettel NR3053 / SDMC MT3053 (MediaTek MT7981B)

#### Nạp từ firmware gốc Viettel / SDMC / Failsafe U-Boot:
1. Đặt IP tĩnh máy tính: `192.168.1.10 / 255.255.255.0`. Cắm dây LAN vào cổng LAN của router.
2. Giữ nút **Reset** và cắm nguồn điện đến khi đèn LED nhấp nháy, truy cập `http://192.168.1.1` trên trình duyệt.
3. Chọn file `openwrt-mediatek-filogic-sdmc_mt3053-squashfs-factory.ubi` và bấm **Update Firmware**.
4. Chờ 3 phút, router khởi động lại là hoàn tất.

#### Nâng cấp từ LuCI OpenWrt (Sysupgrade):
- Dùng file `openwrt-mediatek-filogic-sdmc_mt3053-squashfs-sysupgrade.bin` (layout gốc) hoặc `*viettel_nr3053-squashfs-sysupgrade.bin` (layout U-Boot FIP) nạp trực tiếp qua trang Flash Firmware.

---

### 4. JDCloud Athena AX6600 (RE-CS-02 Qualcomm IPQ6010)

1. **Nạp lần đầu qua U-Boot Failsafe**:
   - Kết nối dây mạng vào cổng LAN 1, giữ nút Reset khi cấp nguồn, truy cập web U-Boot tại `192.168.1.1`.
   - Chọn file `openwrt-qualcommax-ipq60xx-jdcloud_re-cs-02-squashfs-factory.bin` và nạp.
2. **Nâng cấp từ LuCI OpenWrt**:
   - Sử dụng file `openwrt-qualcommax-ipq60xx-jdcloud_re-cs-02-squashfs-sysupgrade.bin` nạp trực tiếp qua LuCI.
   - Định dạng ổ đĩa eMMC 128GB F2FS tự động nhận diện và bảo toàn dữ liệu ứng dụng.

---

### 5. Swaiot S10-SKY (Qualcomm IPQ8071 / IPQ8074 - M.2 PCIe 5G Fibocom FM350-GL & 1GB RAM)

#### 📋 Thông số phần cứng Swaiot S10-SKY:
- **SoC**: Qualcomm IPQ8071 / IPQ8074 Quad-Core Cortex-A53 2.2GHz + Qualcomm NSS NPU.
- **RAM**: 1GB DDR4 3200MHz tốc độ cao.
- **Flash**: Dual-Flash 16MB SPI-NOR + 256MB QPIC NAND (phân vùng động UBI).
- **Mạng**: 1 Cổng WAN 2.5Gbps (Qualcomm QCA8081 SGMII) + 2 Cổng LAN 1Gbps (Qualcomm QCA8075 Switch).
- **Wi-Fi 6**: Qualcomm ath11k AX6000/AX3600 (2.4GHz + 5GHz), tự động bóc tách caldata từ phân vùng `0:ART`.
- **Khe cắm 5G M.2 PCIe 3.0**: Hỗ trợ trực tiếp module Fibocom FM350-GL (MediaTek T700) PCIe MBIM `/dev/wwan0mbim0` & AT `/dev/wwan0at0`, `/dev/ttyFMI*`, Qualcomm MHI PCIe `/dev/mhi_DUN`, và 2 cổng USB 3.0 DWC3.

#### 🚀 Hướng dẫn nạp lần đầu từ Firmware gốc hoặc U-Boot Failsafe:
1. Đặt IP tĩnh trên máy tính: `192.168.1.10 / 255.255.255.0`. Cắm cáp mạng vào cổng LAN của Swaiot S10-SKY.
2. Giữ nút **Reset** và cắm nguồn điện đến khi đèn LED nhấp nháy, mở trình duyệt truy cập `http://192.168.1.1` (Web Failsafe U-Boot) hoặc nạp qua TFTP `tftpboot 0x44000000 *swaiot_s10sky-squashfs-factory.ubi; nand erase.part rootfs; nand write $fileaddr rootfs $filesize`.
3. Chọn file `duydoan-25.12-*-swaiot_s10sky-squashfs-factory.ubi` và bấm **Update Firmware**.
4. Chờ 2 - 3 phút để hệ thống tự phân vùng UBI và khởi động vào giao diện ImmortalWrt Duydoan 25.12.

#### 🔄 Nâng cấp từ LuCI OpenWrt (Sysupgrade):
- Vào menu **Hệ thống (System)** ➔ **Sao lưu / Nạp phần mềm (Backup / Flash Firmware)**.
- Chọn file `duydoan-25.12-*-swaiot_s10sky-squashfs-sysupgrade.bin` và bấm nạp trực tiếp.
- Hoặc qua SSH: `sysupgrade -n -F /tmp/*swaiot_s10sky-squashfs-sysupgrade.bin`.

#### 📶 Hướng dẫn quản trị Modem 5G PCIe & SIM:
- **Giao diện LuCI Web**: Menu **Modem 5G** ➔ **Tiện Ích 5G & Modem** (`/cgi-bin/luci/admin/modem/control`):
  - **Tự động nhận diện**: Fibocom FM350-GL PCIe, Quectel RM500Q/RM520N, Sierra EM919x, SIMCOM.
  - **Cổng AT Modem**: Hiển thị đầy đủ danh sách cổng PCIe `/dev/ttyFMI0`, `/dev/wwan0at0`, `/dev/mhi_DUN` và `/dev/ttyUSB*`.
  - **Đổi TTL né bóp băng thông hotspot**: Mặc định 65 (chống nhà mạng trừ dung lượng hotspot).
  - **Khóa băng tần 5G/4G & Cell Lock**: Khóa cố định các băng tần mạnh nhất (N77, N78, N1, N3, B1, B3, B7, B8).
  - **Đổi IMEI 1-click**: Vượt qua rào cản hạn chế thiết bị của nhà mạng.
  - **Hộp thư SMS 2 chiều**: Đọc tin nhắn OTP, tra cước nhanh (Viettel KTTK, Vina DATA, Mobi KT DATA, Wintel) và hẹn giờ tự động gia hạn gói cước.
- **Lệnh CLI `ati` độc quyền**:
  - Gõ `ati` trong Terminal để kiểm tra toàn bộ thông tin Modem, IMEI, SIM, CSQ, Cell ID, IP WAN.
  - Gõ `ati <lệnh AT>` (ví dụ `ati AT+CSQ`) để gửi lệnh tùy biến tức thì.
- **Cơ chế tự động quay số (`modem_autodial.sh`)**:
  - Tự động nhận thẻ SIM, nhận diện nhà mạng (Viettel, Vinaphone, Mobifone, Wintel) và quay số cấp phát IP Internet hoàn toàn tự động.

---

## 🌿 CẤU TRÚC PHÂN NHÁNH HỆ THỐNG

1. **Nhánh `main` — Bản 24.10 LTS Siêu Ổn Định**:
   - Sử dụng nhân **Linux Kernel 6.6 LTS**.
   - Cố định độ ổn định cao nhất phục vụ nhu cầu chạy mạng sản xuất 24/7.
   - Hỗ trợ tối ưu phần cứng Qualcomm NSS và MediaTek HNAT.
2. **Nhánh `openwrt-25` — Bản 25.12 Bleeding Edge (Công Nghệ Mới)**:
   - Sử dụng nhân **Linux Kernel 6.12**.
   - **Tự Động Đồng Bộ Upstream (Auto-Sync)**: Mỗi sáng lúc 6h15 sẽ tự động kéo các commit mới nhất từ kho gốc `immortalwrt/immortalwrt` (nhánh `openwrt-25.12`), tự động giải quyết xung đột và bảo lưu 100% cấu hình router của Anh Duy.

---

## 🚀 TIẾN TRÌNH BIÊN DỊCH TỰ ĐỘNG HẰNG NGÀY (GITHUB ACTIONS)

- **05:15 AM (ICT)**: `Auto-Clean` (Dọn dẹp Releases, Tags, và Workflow runs cũ)
- **05:25 AM (ICT)**: `Build Duydoan-25.12 ASUS TUF Gaming` (Song song AX6000 & AX4200 - MediaTek MT7986A)
- **05:30 AM (ICT)**: `Build Duydoan-25.12 Swaiot S10-SKY` (Qualcomm IPQ8071/IPQ8074 - M.2 PCIe 5G Fibocom FM350-GL)
- **05:35 AM (ICT)**: `Build Duydoan-25.12 Viettel NR3053 / SDMC MT3053` (MediaTek MT7981B)
- **05:45 AM (ICT)**: `Build Duydoan-25.12 JDCloud RE-CS-02` (Qualcomm IPQ6010 NSS)
- **05:55 AM (ICT)**: `Build Duydoan-24.10 ASUS TUF Gaming` (Song song AX6000 & AX4200 - MediaTek MT7986A)
- **06:05 AM (ICT)**: `Build Duydoan-24.10 Viettel NR3053` (MediaTek MT7981B)
- **06:15 AM (ICT)**: `Build Duydoan-24.10 JDCloud RE-CS-02` (Qualcomm IPQ6010 NSS)
- **06:25 AM (ICT)**: `Build Duydoan-25.12 CMCC RAX3000M` (Song song eMMC & NAND - MediaTek MT7981B)
- **06:35 AM (ICT)**: `Build Duydoan-24.10 CMCC RAX3000M` (Song song eMMC & NAND - MediaTek MT7981B)
- **Cơ chế bảo đảm 24/7 (Self-Healing)**: Máy ảo Debian kích hoạt độc lập lúc 05:20 AM qua crontab để bảo đảm không phụ thuộc vào hàng đợi của GitHub.

---

## 🛠️ TÍNH NĂNG MẠNG TÍCH HỢP SẴN
- **Định tuyến phần cứng**: Qualcomm NSS Hardware Flow Offloading & MediaTek PPE/WED Hardware NAT.
- **Tăng tốc mã hóa**: Qualcomm Crypto Engine & MediaTek SafeXcel EIP-97.
- **Ứng dụng mạng cao cấp**: PassWall, SSR-Plus, Bypass, dae, TTYD Web Terminal, BBR Congestion Control.
- **Hỗ trợ kết nối WAN**: PPPoE, DHCP, Dual-WAN Load Balancing (mwan3), Modem di động 4G/5G qua giao thức MBIM/QMI/ECM.
- **Giao diện Master Dashboard**: Tích hợp nút tắt 1-click `[⚡ Master Dashboard]` cố định, theo dõi thời tiết, trạng thái CPU, nhiệt độ, SIM/Modem 5G, kiểm tra độ trễ Game QoS và nút gạt HNAT tức thì.

---

### 4. Wireless-Tag ZX7981PD (5G CPE Development Board)

#### Danh mục file nạp tương ứng:
- `*wirelesstag_zx7981pd-squashfs-factory.bin`: Dành cho nạp lần đầu qua Web Failsafe U-Boot (hoặc cứu brick).
- `*wirelesstag_zx7981pd-squashfs-sysupgrade.bin`: Nâng cấp trực tiếp qua giao diện Web LuCI (System ➔ Backup / Flash Firmware).
- `*wirelesstag_zx7981pd-initramfs-kernel.bin`: Firmware chạy trực tiếp trên RAM qua TFTP / U-Boot console `tftpboot 0x44000000 <file>; bootm`.

#### 🚀 Hướng dẫn nạp lần đầu qua U-Boot Failsafe Web:
1. Nối dây mạng LAN từ máy tính vào **Cổng LAN 1** của bo mạch WirelessTag ZX7981PD.
2. Đặt IP tĩnh trên máy tính: `192.168.1.10`, subnet mask `255.255.255.0`, gateway `192.168.1.1`.
3. Giữ nút **Reset** trên mạch và cắm nguồn điện. Đợi 5 giây cho đèn trạng thái chuyển sang nhấp nháy rồi thả tay.
4. Mở trình duyệt web truy cập `http://192.168.1.1` (Giao diện phục hồi U-Boot Web Failsafe).
5. Chọn file `doanduy-*-wirelesstag_zx7981pd-squashfs-factory.bin` và bấm **Upload / Update**.
6. Đợi khoảng 2 - 3 phút để hệ thống ghi flash SPI-NAND và tự khởi động lại vào ImmortalWrt Duydoan.

#### 🔄 Nâng cấp trực tiếp từ LuCI (Sysupgrade):
- Vào menu **Hệ thống (System)** ➔ **Sao lưu / Nạp phần mềm (Backup / Flash Firmware)**.
- Chọn file `doanduy-*-wirelesstag_zx7981pd-squashfs-sysupgrade.bin` và tiến hành nạp giữ cấu hình hoặc xóa trắng cấu hình tùy nhu cầu.
- Hoặc nâng cấp nhanh qua SSH: `sysupgrade -n -F /tmp/*wirelesstag_zx7981pd-squashfs-sysupgrade.bin`.

#### 📶 Quản trị Modem 5G M.2 & SIM:
- **Tự động kích hoạt & Quay số**: Firmware tích hợp sẵn `modem_autodial.sh`, tự động quét nhận diện card 5G (Fibocom FM350-GL PCIe, Quectel RM500Q/RM520N, Sierra EM919x, SIMCOM), kiểm tra thẻ SIM và tự động thiết lập kết nối mạng Internet.
- **Tiện ích LuCI 5G (`Modem 5G` ➔ `Tiện Ích 5G & Modem`)**:
  - Giao thức kết nối: Hỗ trợ linh hoạt MBIM, QMI, ECM, RNDIS, ECM.
  - Cổng AT Modem: Tự động liệt kê các cổng AT `/dev/wwan0at0`, `/dev/ttyUSB*`, `/dev/mhi_DUN`.
  - Khóa băng tần 5G/4G: Khóa mạng Viettel, VinaPhone, MobiFone, Wintel nhanh chóng.
  - Đổi TTL 65: Ngăn chặn nhà mạng trừ dung lượng phát Wi-Fi Hotspot.
  - Lệnh `ati` trong Terminal: Gõ `ati` để kiểm tra toàn bộ thông tin Modem, CSQ, IMEI, Cell ID.
