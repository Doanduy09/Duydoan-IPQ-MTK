# ImmortalWrt 24.10 for JDCloud Athena AX6600 (RE-CS-02) Full Power Edition

Bản phân phối ImmortalWrt 24.10 chuyên dụng tối ưu hóa phần cứng toàn diện cho **JDCloud Athena AX6600 (Model: RE-CS-02)**.
Được thiết kế và tinh chỉnh bởi đội ngũ kỹ thuật cao cấp Antigravity dành riêng cho **Anh Duy (DOANDUY)**.

---

## 🚀 Tính Năng & Đột Phá Kỹ Thuật

### 1. Qualcomm NSS Hardware Acceleration (Tăng Tốc Phần Cứng Độc Quyền)
- Tích hợp trọn bộ driver **Qualcomm NSS 12.5 (Network Subsystem)**: qca-nss-drv, qca-nss-ecm, qca-nss-dp, qca-nss-fw-ipq60xx.
- **Tăng tốc modem di động toàn diện (Cellular Modem Acceleration)**:
  - Hỗ trợ tăng tốc phần cứng NSS trực tiếp cho giao thức ARPHRD_RAWIP qua module ECM (ECM_INTERFACE_RAWIP_ENABLE=y).
  - Hỗ trợ tối đa các giao thức modem 4G/5G: **MBIM**, **QMI (RAW-IP)**, **XMM**, **ModemManager**, **ECM**, **RNDIS**, **CDC-NCM**.
  - Đã loại bỏ hoàn toàn luci-app-sqm và SQM scripts để triệt tiêu độ trễ và hiện tượng nghẽn cổ chai (bottleneck) khi NSS hoạt động ở tốc độ đa gigabit.
  - Tự động tắt flow_offloading phần mềm của firewall và packet_steering để luồng mạng chuyển tiếp trực tiếp vào NSS Core mà không bị CPU can thiệp.

### 2. Mở Khóa Toàn Bộ Bộ Nhớ Flash eMMC (64GB / 128GB F2FS)
- Tự động nhận diện dung lượng eMMC chưa cấp phát (phần dung lượng thừa ngoài 26 phân vùng mặc định của JDCloud).
- Khởi tạo an toàn phân vùng thứ 27 (/dev/mmcblk0p27), định dạng tệp tin tối ưu cho bộ nhớ flash **F2FS** (AthenaStorage).
- Tự động gắn kết vào /mnt/storage lúc khởi động hệ thống (START=95).
- Tự động liên kết mềm các thư mục tài nguyên lớn: /opt -> /mnt/storage/opt và /docker -> /mnt/storage/docker.
- Đảm bảo **100% không bị lỗi khôi phục cài đặt gốc sau khi reboot** (overlay bảo toàn trên phân vùng loop).

### 3. Triple-Band Wi-Fi 6 Cực Đại (Tri-Band AX6600)
- **Băng tần 2.4GHz**: 2x2 MIMO 802.11ax (tích hợp trên SoC IPQ6010).
- **Băng tần 5.2GHz (Low Band)**: 2x2 MIMO 802.11ax (tích hợp trên SoC IPQ6010).
- **Băng tần 5.8GHz (High Band)**: 4x4 MIMO 802.11ax với độ rộng kênh **160MHz** (chipset chuyên dụng Qualcomm QCN9074).
- Tích hợp chuẩn caldata trích xuất từ phân vùng gốc 
