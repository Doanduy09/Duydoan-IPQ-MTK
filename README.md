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

## 📌 DANH MỤC THIẾT BỊ HỖ TRỢ CHÍNH THỨC

| Thiết Bị | Kiến Trúc Vi Xử Lý & Phần Cứng | Bộ Tăng Tốc Phần Cứng & HNAT | Đóng Gói Cấu Hình Đặc Biệt |
| :--- | :--- | :--- | :--- |
| **ASUS TUF Gaming AX6000** | MediaTek MT7986A Filogic 830 (4x 2.0 GHz)<br>RAM 512MB/1GB DDR3/DDR4, Flash 256MB | **MediaTek Dual-PPE HNAT (32,768 luồng)**<br>+ mt7915e WED Turbo Direct DMA<br>+ SafeXcel EIP-97 Crypto Engine<br>+ **Nút Bật/Tắt HNAT 1-Click trên LuCI** | • 2 Cổng 2.5Gbps WAN/LAN + 4 Cổng 1Gbps LAN<br>• Wi-Fi 6 4T4R AX6000 (160MHz Dual MT7976GN)<br>• Cổng USB 3.0 cắm ổ cứng/Modem 5G<br>• Giao diện Master Dashboard Chuyên Sâu |
| **ASUS TUF Gaming AX4200** | MediaTek MT7986A Filogic 830 (4x 2.0 GHz)<br>RAM 512MB DDR3, Flash 256MB | **MediaTek Dual-PPE HNAT (32,768 luồng)**<br>+ mt7915e WED Turbo Direct DMA<br>+ SafeXcel EIP-97 Crypto Engine<br>+ **Nút Bật/Tắt HNAT 1-Click trên LuCI** | • 1 Cổng 2.5Gbps WAN/LAN + 4 Cổng 1Gbps LAN<br>• Wi-Fi 6 AX4200 (4T4R 5GHz 160MHz + 2T2R 2.4GHz)<br>• Cổng USB 3.0 cắm ổ cứng/Modem 5G<br>• Giao diện Master Dashboard Chuyên Sâu |
| **Viettel NR3053 / SDMC MT3053** | MediaTek MT7981B Filogic 820 (2x 1.3 GHz)<br>RAM 512MB DDR3, Flash 128MB SPI-NAND | **MediaTek PPE v2 HNAT (WED Turbo)**<br>+ SafeXcel EIP-97 Crypto Engine<br>+ **Nút Bật/Tắt HNAT 1-Click trên LuCI** | • 1 Cổng 2.5G/1G WAN + 3 Cổng 1G LAN<br>• Wi-Fi 6 AX3000 (2x2 5GHz 160MHz + 2x2 2.4GHz)<br>• Mod phần cứng USB 3.0 cắm Modem 5G ngoài<br>• Giao diện Master Dashboard Chuyên Sâu |
| **JDCloud Athena AX6600 (RE-CS-02)** | Qualcomm IPQ6010 (4x 1.2 GHz)<br>RAM 1GB DDR4, Flash 128GB eMMC F2FS | **Qualcomm NSS 12.5 Hardware Max**<br>+ ECM Flow Offload (NSS Core 0/1)<br>+ Qualcomm Crypto Acceleration | • eMMC 128GB F2FS cài đặt app không giới hạn<br>• Màn hình LED ma trận hiển thị đồng hồ & trạng thái<br>• Hỗ trợ khe cắm module WWAN M.2 5G Sierra/Quectel<br>• Wi-Fi 6 Tri-Band AX6600 (Qualcomm ath11k) |

---

## ⚡ CƠ CHẾ TĂNG TỐC PHẦN CỨNG MEDIATEK HNAT (PPE + WED TURBO)

Trên các dòng router MediaTek Filogic (ASUS TUF-AX6000, ASUS TUF-AX4200, Viettel NR3053):
1. **MediaTek PPE (Packet Processing Engine)**:
   - MT7986A trang bị **Dual-PPE Engine** với năng lực định tuyến phần cứng lên tới **32,768 kết nối đồng thời**.
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

### 2. Viettel NR3053 / SDMC MT3053 (MediaTek MT7981B)

#### Nạp từ firmware gốc Viettel / SDMC / Failsafe U-Boot:
1. Đặt IP tĩnh máy tính: `192.168.1.10 / 255.255.255.0`. Cắm dây LAN vào cổng LAN của router.
2. Giữ nút **Reset** và cắm nguồn điện đến khi đèn LED nhấp nháy, truy cập `http://192.168.1.1` trên trình duyệt.
3. Chọn file `openwrt-mediatek-filogic-sdmc_mt3053-squashfs-factory.ubi` và bấm **Update Firmware**.
4. Chờ 3 phút, router khởi động lại là hoàn tất.

#### Nâng cấp từ LuCI OpenWrt (Sysupgrade):
- Dùng file `openwrt-mediatek-filogic-sdmc_mt3053-squashfs-sysupgrade.bin` (layout gốc) hoặc `*viettel_nr3053-squashfs-sysupgrade.itb` (layout U-Boot FIP) nạp trực tiếp qua trang Flash Firmware.

---

### 3. JDCloud Athena AX6600 (RE-CS-02 Qualcomm IPQ6010)

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

- **06:00 AM (ICT)**: `Build Duydoan-24.10 JDCloud RE-CS-02` (Qualcomm NSS)
- **06:10 AM (ICT)**: `Build Duydoan-24.10 ASUS TUF Gaming (All Devices)` (Song song AX6000 & AX4200)
- **06:15 AM (ICT)**: `Build Duydoan-25.12 JDCloud RE-CS-02 (Bleeding Edge)` (Qualcomm NSS + Auto-Sync)
- **06:25 AM (ICT)**: `Build Duydoan-25.12 ASUS TUF Gaming (All Devices - Bleeding Edge)` (MediaTek HNAT + Auto-Sync)
- **06:30 AM (ICT)**: `Build Duydoan-25.12 Viettel NR3053 / SDMC MT3053 (Bleeding Edge)` (MediaTek MT7981B + USB 3.0 Mod + Auto-Sync)
- **Cơ chế dọn dẹp (Self-Cleaning)**: Tự động xóa các bản phát hành cũ của từng router trước khi tạo bản mới, bảo đảm không bao giờ bị trùng lặp hoặc tốn dung lượng GitHub.

---

## 🛠️ TÍNH NĂNG MẠNG TÍCH HỢP SẴN
- **Định tuyến phần cứng**: Qualcomm NSS Hardware Flow Offloading & MediaTek PPE/WED Hardware NAT.
- **Tăng tốc mã hóa**: Qualcomm Crypto Engine & MediaTek SafeXcel EIP-97.
- **Ứng dụng mạng cao cấp**: PassWall, SSR-Plus, Bypass, dae, TTYD Web Terminal, BBR Congestion Control.
- **Hỗ trợ kết nối WAN**: PPPoE, DHCP, Dual-WAN Load Balancing (mwan3), Modem di động 4G/5G qua giao thức MBIM/QMI/ECM.
- **Giao diện Master Dashboard**: Tích hợp nút tắt 1-click `[⚡ Master Dashboard]` cố định, theo dõi thời tiết, trạng thái CPU, nhiệt độ, SIM/Modem 5G, kiểm tra độ trễ Game QoS và nút gạt HNAT tức thì.
