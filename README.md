# Duydoan ImmortalWrt Multi-Generation Firmware Suite (`SNAPSHOT` Kernel 6.18 • `25.12` Kernel 6.12 • `24.10` Kernel 6.6)

Hệ thống biên dịch tự động Multi-Target cho router **Qualcomm IPQ60xx / IPQ807x** và **MediaTek Filogic (MT7981 / MT7986 / MT7987 / MT7988)**, tích hợp sẵn trình quay số 5G & Nhà Thông Minh `luci-app-doanduy-modem` v2.5.0+ (thay thế hoàn toàn file `all` cũ đã xóa bỏ), LuCI Argon Tiếng Việt và tối ưu phần cứng riêng cho từng thế hệ Kernel.

---

## 🗂️ Bảng Ánh Xạ Chuẩn 1-1: 6 Nhánh Mã Nguồn ↔ 8 Kịch Bản GitHub Actions

| STT | Nhánh Mã Nguồn (Branches) | Gốc Đồng Bộ Upstream & Kernel | Dòng Máy Build Cụ Thể | PassWall | Tên Kịch Bản Trên GitHub Actions (Workflows) |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **1** | **`master`** *(default)* | **`immortalwrt/immortalwrt:master`** (`SNAPSHOT`, **Kernel `6.18`**, `apk`) | **IPQ60xx** + **IPQ807x** + **Filogic (MT7981/7986/7987/7988)** | ❌ `[Không PassWall]` | `[master] Build IPQ60xx + IPQ807x + Filogic (SNAPSHOT Kernel 6.18) [Không PassWall]` |
| **2** | **`master-passwall`** | **`immortalwrt/immortalwrt:master`** (`SNAPSHOT`, **Kernel `6.18`**, `apk`) | **IPQ60xx** + **IPQ807x** + **Filogic (MT7981/7986/7987/7988)** | ✅ `[Có PassWall]` (`xray`, `sing-box`, `chinadns-ng`, `haproxy`) | `[master-passwall] Build IPQ60xx + IPQ807x + Filogic (SNAPSHOT Kernel 6.18) [Có PassWall]` |
| **3** | **`immortalwrt-24`** | **`immortalwrt:openwrt-24.10`** (`24.10`, **Kernel `6.6`**, `opkg`, NSS 12.5) | **IPQ60xx** (12 máy) + **IPQ807x** (38 máy) + **Filogic** (65 máy) | ❌ `[Không PassWall]` | `[immortalwrt-24] Build IPQ60xx + IPQ807x + Filogic (24.10 Kernel 6.6) [Không PassWall]` |
| **4** | **`immortalwrt-24-passwall`** | **`immortalwrt:openwrt-24.10`** (`24.10`, **Kernel `6.6`**, `opkg`, NSS 12.5) | **IPQ60xx** (12 máy) + **IPQ807x** (38 máy) + **Filogic** (65 máy) | ✅ `[Có PassWall]` | `[immortalwrt-24-passwall] Build IPQ60xx + IPQ807x + Filogic (24.10 Kernel 6.6) [Có PassWall]` |
| **5** | **`qualcomm-nss-25.12`** | **ImmortalWrt `25.12`** (`LiBwrt`, **Kernel `6.12`**, `apk`, **Full-NSS 12.5**) | **Chỉ Qualcomm IPQ:** **IPQ60xx** (All) + **IPQ807x** (All) | ⚙️ Chọn `false` / `true` / `both` | `[qualcomm-nss-25.12] Build IPQ60xx + IPQ807x (Kernel 6.12 Full-NSS)` |
| **6** | **`filogic-wed-25.12`** | **ImmortalWrt `25.12`** (`chasey-dev`, **Kernel `6.12`**, `apk`, **`mt_wifi` + WED**) | **Chỉ MediaTek Filogic:** **MT7981 AX3000** (97 máy) + **MT7986 AX6000** (25 máy) | ⚙️ Chọn `false` / `true` / `both` | `[filogic-wed-25.12] Build MediaTek MT7981 + MT7986 (Kernel 6.12 WED)` |
| **7** | *(Hệ thống)* | Dọn rác tự động 00:30 hằng ngày | Giữ 1 Release & 1 Cache mới nhất/dòng chip; bảo vệ run đang chạy | — | `Auto-Clean & Release Purge` |
| **8** | *(Hệ thống)* | Đồng bộ tự động 01:00 & 13:00 hằng ngày | `master*` ← `immortalwrt:master` (`SNAPSHOT`); `immortalwrt-24*` ← `openwrt-24.10` | — | `Sync Upstream ImmortalWrt (master->SNAPSHOT & 24.10->immortalwrt-24)` |
