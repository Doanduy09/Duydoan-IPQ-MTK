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
| **Viettel NR3053 / SDMC MT3053** | • **SoC**: MediaTek MT7981B Filogic 820 (2x 1.3 GHz)<br>• **RAM**: 512MB DDR3<br>• **Flash**: 128MB SPI-NAND<br>• **Cổng mạng**: 1 Cổng 1Gbps WAN + 3 Cổng 1Gbps LAN (1000Mbps Full Duplex)<br>• **Wi-Fi 6**: 2T2R AX3000 (2.4G 574M + 5G 2402M HE160)<br>• **USB**: Mod phần cứng USB 3.0 cắm Modem 5G ngoài | **MediaTek PPE v2 HNAT (WED Turbo)**<br>+ SafeXcel EIP-97 Crypto Engine<br>+ **Công tắc HNAT 1-Click trên LuCI** | • Tương thích 100% layout gốc SDMC factory.ubi và U-Boot FIP<br>• Hiệu chuẩn EEPROM sóng Wi-Fi chuẩn xác 100%<br>• Master Dashboard & 1-Click Auto Mesh |

---

### 🔹 NHÓM 3: QUALCOMM IPQ6010 / IPQ6000 (4 NHÂN CORTEX-A53 1.2 GHz + NPU NSS)

| Thiết Bị | Kiến Trúc Phần Cứng & Cấu Hình Chi Tiết | Tăng Tốc Phần Cứng & NSS | Tính Năng Đặc Biệt |
| :--- | :--- | :--- | :--- |
| **JDCloud Athena AX6600 (RE-CS-02)** | • **SoC**: Qualcomm IPQ6010 (4x 1.2 GHz)<br>• **RAM**: 1GB DDR4<br>• **Flash**: **128GB eMMC F2FS**<br>• **Cổng mạng**: 1 Cổng 2.5Gbps WAN/LAN + 4 Cổng 1Gbps LAN<br>• **Wi-Fi 6**: Tri-Band AX6600 (2.4G + 5.2G + 5.8G Qualcomm ath11k)<br>• **Mở rộng**: Khe cắm module WWAN M.2 5G Sierra/Quectel + LED ma trận | **Qualcomm NSS 12.5 Hardware Max**<br>+ ECM Flow Offload (NSS Core 0/1)<br>+ Qualcomm Crypto Acceleration | • eMMC 128GB F2FS siêu tốc cài đặt app không giới hạn<br>• Màn hình LED ma trận hiển thị đồng hồ thời gian & trạng thái mạng<br>• Hỗ trợ module WWAN 5G khe M.2 trong thân máy |

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
