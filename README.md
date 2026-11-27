# Duydoan ImmortalWrt Firmware Suite (`25.12` Kernel 6.12 Full-NSS / WED • `SNAPSHOT` Kernel 6.18)

Hệ thống biên dịch tự động Multi-Target cho router **Qualcomm IPQ60xx / IPQ807x** và **MediaTek Filogic (MT7981 / MT7986 / MT7987 / MT7988)**, tích hợp sẵn trình quay số 5G & Nhà Thông Minh `luci-app-doanduy-modem` v2.5.0+, LuCI Argon Tiếng Việt, nhận diện chuẩn `DOANDUY` (`DOANDUY_2.4G` / `DOANDUY_5G`).

---

## 🗂️ Bảng Ánh Xạ Chuẩn 1-1: 4 Nhánh Chiến Lược ↔ 6 Kịch Bản GitHub Actions

| STT | Nhánh Mã Nguồn | Nền Tảng & Kernel | Tăng Tốc Phần Cứng | Dòng Máy Build | PassWall | Kịch Bản GitHub Actions |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **`qualcomm-nss-25.12`** | **ImmortalWrt `25.12`** (`Kernel 6.12`, `apk`) | **Full-NSS 12.5** (`NSS-LibWrt` + `sqm-scripts-nss`) | **Chỉ Qualcomm IPQ:** `IPQ60xx` + `IPQ807x` (`ALL_PROFILES`) | ⚙️ Chọn `false` / `true` / `both` | `[qualcomm-nss-25.12] Build IPQ60xx + IPQ807x (Kernel 6.12 Full-NSS)` |
| **2** | **`filogic-wed-25.12`** | **ImmortalWrt `25.12`** (`Kernel 6.12`, `apk`) | **`mt_wifi` + HNAT/WED** | **Chỉ MediaTek Filogic:** `MT7981 AX3000` (97 máy) + `MT7986 AX6000` (25 máy) | ⚙️ Chọn `false` / `true` / `both` | `[filogic-wed-25.12] Build MediaTek MT7981 + MT7986 (Kernel 6.12 WED)` |
| **3** | **`master`** *(default)* | **ImmortalWrt `SNAPSHOT`** (`Kernel 6.18`, `apk`) | **Không NSS** (`ath11k` / `mt76` + `nft-offload`) | `IPQ60xx` + `IPQ807x` + `Filogic (MT7981/7986/7987/7988)` | ❌ `[Không PassWall]` | `[master] Build IPQ60xx + IPQ807x + Filogic (SNAPSHOT K6.18 \| Không NSS \| nft-offload) [Không PassWall]` |
| **4** | **`master-passwall`** | **ImmortalWrt `SNAPSHOT`** (`Kernel 6.18`, `apk`) | **Không NSS** (`ath11k` / `mt76` + `nft-offload`) | `IPQ60xx` + `IPQ807x` + `Filogic (MT7981/7986/7987/7988)` | ✅ `[Có PassWall]` (`xray`, `sing-box`, `chinadns-ng`, `haproxy`) | `[master-passwall] Build IPQ60xx + IPQ807x + Filogic (SNAPSHOT K6.18 \| Không NSS \| nft-offload) [Có PassWall]` |
| **5** | *(Hệ thống)* | Dọn rác tự động `00:30` hằng ngày | Giữ 1 Release & 1 Cache mới nhất/dòng chip; bảo vệ run đang chạy | — | — | `Auto-Clean & Release Purge` |
| **6** | *(Hệ thống)* | Đồng bộ tự động `01:00` & `13:00` hằng ngày | `master` & `master-passwall` ← `immortalwrt:master` | — | — | `Sync Upstream ImmortalWrt (master->SNAPSHOT)` |

> **Lưu ý lịch sử:** Nhánh `immortalwrt-24` / `immortalwrt-24-passwall` (Kernel 6.6) đã ngừng duy trì để dồn toàn lực cho Kernel 6.12 (`25.12`) và Kernel 6.18 (`master`, sẵn sàng cho Wi-Fi 7). Bản lưu trữ cuối cùng được giữ tại Git tag `archive/immortalwrt-24-final`.

---

## 🧭 Chọn Nhanh Bản ROM Phù Hợp

- **Router Qualcomm IPQ60xx / IPQ807x (JDC AX6600, Swaiot S10-SKY, Xiaomi AX3600/AX6/AX9000...):**
  - Muốn **Full-NSS 12.5** (nhẹ CPU, NAT/PPPoE tốc độ cao) 👉 chọn **`qualcomm-nss-25.12`** (Kernel 6.12).
  - Muốn **Kernel 6.18 mới nhất / không dùng NSS** 👉 chọn **`master`** hoặc **`master-passwall`**.
- **Router MediaTek Filogic (ASUS TUF-AX4200/AX6000, Viettel NR3053, Cudy, Xiaomi AX3000T/AX6000...):**
  - Muốn **`mt_wifi` + HNAT/WED** (sóng Wi-Fi khỏe, offload phần cứng MT7981/MT7986) 👉 chọn **`filogic-wed-25.12`** (Kernel 6.12).
  - Muốn **`mt76` open-source / MT7988 / Wi-Fi 7 / Kernel 6.18** 👉 chọn **`master`** hoặc **`master-passwall`**.

## ⚠️ Quy Tắc Flash An Toàn
1. **Không tích *Keep settings*** khi chuyển giữa bản **Full-NSS** ↔ **Không NSS**, giữa **`mt_wifi`** ↔ **`mt76`**, hoặc giữa các thế hệ Kernel (`6.12` ↔ `6.18`).
2. Kiểm tra mã toàn vẹn **`sha256sums`** kèm trong Release trước khi nạp firmware.
3. Tên file chuẩn hóa sẵn theo cấu trúc: `Doanduy-<PhiênBản>-<PassWall|NoPassWall>-<target>-<model>-<sysupgrade|factory>.bin`.
