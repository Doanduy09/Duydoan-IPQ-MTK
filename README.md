# Duydoan ImmortalWrt 25.12 & 24.10 Multi-Branch Firmware Suite

Hệ thống biên dịch tự động Multi-Target cho router **Qualcomm IPQ60xx / IPQ807x** và **MediaTek Filogic (MT7981 / MT7986 / MT7987 / MT7988)**, tích hợp sẵn bộ quản trị Modem 5G & Nhà Thông Minh `luci-app-doanduy-modem` v2.5.0+ (Fibocom FM350-GL, Quectel RM502Q/RM520N, Sierra EM9190, SmartHome Auto-Probe IP), LuCI Argon Tiếng Việt và tối ưu phần cứng riêng cho từng dòng SoC.

---

## 🗂️ Bảng Ánh Xạ Chuẩn 1-1: 6 Nhánh Mã Nguồn ↔ 8 Kịch Bản GitHub Actions

Mỗi nhánh trong repo có **1 kịch bản GitHub Actions riêng biệt mang đúng tên nhánh đó**, hiển thị rõ **Nhánh nào + Dòng chip nào + Có/Không PassWall** ngay trên danh sách Actions:

| STT | Nhánh Mã Nguồn (Branches) | Nền Tảng / Kernel / Feeds | Dòng Máy Build Cụ Thể | PassWall | Tên Kịch Bản Trên GitHub Actions (Workflows) | Lịch Tự Động (Giờ VN) |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **`master`** *(mặc định)* | ImmortalWrt Snapshot — Kernel `6.6` + Feeds `25.12` | **IPQ60xx** (12 máy) + **IPQ807x** (38 máy) + **Filogic** (65 máy) | ❌ `[Không PassWall]` | `[master] Build IPQ60xx + IPQ807x + Filogic [Không PassWall]` (`build-master.yml`) | 01:30 Thứ 2 & Thứ 5 |
| **2** | **`master-passwall`** | ImmortalWrt Snapshot — Kernel `6.6` + Feeds `25.12` | **IPQ60xx** (12 máy) + **IPQ807x** (38 máy) + **Filogic** (65 máy) | ✅ `[Có PassWall]` (`xray`, `sing-box`, `chinadns-ng`, `haproxy`) | `[master-passwall] Build IPQ60xx + IPQ807x + Filogic [Có PassWall]` (`build-master-passwall.yml`) | 04:00 Thứ 2 & Thứ 5 |
| **3** | **`immortalwrt-24`** | ImmortalWrt 24.10 Stable — Kernel `6.6` + Feeds `24.10` | **IPQ60xx** (12 máy) + **IPQ807x** (38 máy) + **Filogic** (65 máy) | ❌ `[Không PassWall]` | `[immortalwrt-24] Build IPQ60xx + IPQ807x + Filogic [Không PassWall]` (`build-immortalwrt-24.yml`) | 01:30 Thứ 3 & Thứ 6 |
| **4** | **`immortalwrt-24-passwall`** | ImmortalWrt 24.10 Stable — Kernel `6.6` + Feeds `24.10` | **IPQ60xx** (12 máy) + **IPQ807x** (38 máy) + **Filogic** (65 máy) | ✅ `[Có PassWall]` (`xray`, `sing-box`, `chinadns-ng`, `haproxy`) | `[immortalwrt-24-passwall] Build IPQ60xx + IPQ807x + Filogic [Có PassWall]` (`build-immortalwrt-24-passwall.yml`) | 04:00 Thứ 3 & Thứ 6 |
| **5** | **`qualcomm-nss-25.12`** | ImmortalWrt 25.12 (`LiBwrt`) — **Kernel `6.12`** + **Qualcomm Full-NSS 12.5** + `sqm-scripts-nss` | **Chỉ Qualcomm IPQ:** **IPQ60xx** (All) + **IPQ807x** (All) | ⚙️ Chọn `false` / `true` / `both` | `[qualcomm-nss-25.12] Build IPQ60xx + IPQ807x (Kernel 6.12 Full-NSS)` (`build-qualcomm-nss-25.12.yml`) | 01:30 Thứ 4 (Thuần) & CN (PassWall) |
| **6** | **`filogic-wed-25.12`** | ImmortalWrt 25.12 (`chasey-dev`) — **Kernel `6.12`** + **MediaTek `mt_wifi` + HNAT/WED** | **Chỉ MediaTek Filogic:** **MT7981 AX3000** (97 máy) + **MT7986 AX6000** (25 máy) | ⚙️ Chọn `false` / `true` / `both` | `[filogic-wed-25.12] Build MediaTek MT7981 + MT7986 (Kernel 6.12 WED)` (`build-filogic-wed-25.12.yml`) | 04:00 Thứ 4 (Thuần) & CN (PassWall) |
| **7** | *(Bảo trì hệ thống)* | Dọn dẹp thông minh | Giữ 1 Release & 1 Cache mới nhất/dòng chip; **bảo vệ tuyệt đối run đang chạy** | — | `Auto-Clean & Release Purge` (`Auto-Clean.yml`) | 00:30 Hằng ngày |
| **8** | *(Đồng bộ mã nguồn)* | Merge `immortalwrt:openwrt-24.10` | Đồng bộ an toàn 4 nhánh Kernel `6.6` (`master*`, `immortalwrt-24*`), khóa file riêng Doanduy | — | `Sync Upstream ImmortalWrt 24.10 (4 Nhánh Kernel 6.6)` (`sync-immortalwrt.yml`) | 01:00 & 13:00 Hằng ngày |

---

## ⚡ Chọn Nhanh Dòng Chip Khi Bấm "Run workflow" Thủ Công

- Trên 4 nhánh **`master`**, **`master-passwall`**, **`immortalwrt-24`**, **`immortalwrt-24-passwall`**:
  - `all`: Build trọn bộ cả **3 dòng** (`Qualcomm IPQ60xx` + `Qualcomm IPQ807x` + `MediaTek Filogic`).
  - `qualcomm-ipq`: Build riêng **cả 2 dòng Qualcomm IPQ** (`IPQ60xx` + `IPQ807x`).
  - `qualcomm-ipq60xx` / `qualcomm-ipq807x` / `mediatek-filogic`: Build lẻ đúng 1 dòng chip.
- Trên nhánh **`qualcomm-nss-25.12`**:
  - `all`: Build trọn bộ **Qualcomm IPQ60xx + IPQ807x** (Kernel 6.12 Full-NSS 12.5).
  - Chọn kèm `passwall = false` (Thuần), `true` (Có PassWall) hoặc `both` (Cả hai).
- Trên nhánh **`filogic-wed-25.12`**:
  - `all`: Build trọn bộ **MediaTek MT7981 + MT7986** (Kernel 6.12 `mt_wifi` + WED).
  - Chọn kèm `passwall = false`, `true` hoặc `both`.
