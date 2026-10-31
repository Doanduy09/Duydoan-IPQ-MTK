# Duydoan ImmortalWrt 24.10 LTS & 25.12 Multi-Platform CI/CD Firmware Suite

<div align="center">

[![Distro Version](https://img.shields.io/badge/Duydoan-24.10%20LTS%20%26%2025.12-007ec6.svg?style=for-the-badge&logo=openwrt)](https://github.com/Doanduy09/Duydoan-ImmortalWrt)
[![Qualcomm NSS](https://img.shields.io/badge/Qualcomm-NSS%2012.5%20Hardware%20Max-brightgreen.svg?style=for-the-badge&logo=qualcomm)](https://github.com/Doanduy09/Duydoan-ImmortalWrt)
[![MediaTek HNAT](https://img.shields.io/badge/MediaTek-PPE%20%2B%20WED%20HNAT%20Max-ff69b4.svg?style=for-the-badge)](https://github.com/Doanduy09/Duydoan-ImmortalWrt)
[![Crypto Accel](https://img.shields.io/badge/Crypto-SafeXcel%20EIP--97-orange.svg?style=for-the-badge)](https://github.com/Doanduy09/Duydoan-ImmortalWrt)
[![Daily Build](https://img.shields.io/badge/Auto%20Build-Daily%2006%3A00%20ICT-success.svg?style=for-the-badge&logo=githubactions)](https://github.com/Doanduy09/Duydoan-ImmortalWrt/actions)
[![Maintained By](https://img.shields.io/badge/Author-Doanduy09-blue.svg?style=for-the-badge&logo=github)](https://github.com/Doanduy09)

**Hệ thống biên dịch và phát hành firmware tự động tối ưu hóa kịch trần năng lực phần cứng cho các dòng Router cao cấp Qualcomm & MediaTek.**  
*Được duy trì và phát triển bởi Anh Duy (DOANDUY).*

</div>

---

## 📌 DANH MỤC THIẾT BỊ HỖ TRỢ CHÍNH THỨC

| Thiết Bị | Kiến Trúc Vi Xử Lý | Bộ Tăng Tốc Phần Cứng | Đóng Gói Cấu Hình Đặc Biệt |
| :--- | :--- | :--- | :--- |
| **JDCloud Athena AX6600 (RE-CS-02)** | Qualcomm IPQ6010 (4x 1.2 GHz) | **Qualcomm NSS 12.5 + ECM + ath11k** | eMMC 128GB F2FS, Modem 5G Sierra, Màn hình LED Athena |
| **ASUS TUF Gaming AX6000** | MediaTek MT7986A Filogic 830 (4x 2.0 GHz) | **MediaTek HNAT (PPE + WED) + SafeXcel EIP-97** | Dual 2.5Gbps WAN/LAN, Wi-Fi 6 4x4 AX6000, Full App Suite |
| **ASUS TUF Gaming AX4200** | MediaTek MT7986A Filogic 830 (4x 2.0 GHz) | **MediaTek HNAT (PPE + WED) + SafeXcel EIP-97** | 2.5Gbps WAN/LAN, Wi-Fi 6 AX4200, Full App Suite |

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
- **Cơ chế dọn dẹp (Self-Cleaning)**: Tự động xóa các bản phát hành cũ của từng router trước khi tạo bản mới, bảo đảm không bao giờ bị trùng lặp hoặc tốn dung lượng GitHub.

---

## 🛠️ TÍNH NĂNG MẠNG TÍCH HỢP SẴN
- **Định tuyến phần cứng**: Qualcomm NSS Hardware Flow Offloading & MediaTek PPE/WED Hardware NAT.
- **Tăng tốc mã hóa**: Qualcomm Crypto Engine & MediaTek SafeXcel EIP-97.
- **Ứng dụng mạng cao cấp**: PassWall, SSR-Plus, Bypass, dae, TTYD Web Terminal, BBR Congestion Control.
- **Hỗ trợ kết nối WAN**: PPPoE, DHCP, Dual-WAN Load Balancing (mwan3), Modem di động 4G/5G qua giao thức MBIM/QMI/ECM.
