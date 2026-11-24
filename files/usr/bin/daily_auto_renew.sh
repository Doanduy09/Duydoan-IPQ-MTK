#!/bin/sh
export TZ='<+07>-7'
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

LOG_FILE="/tmp/daily_auto_renew.log"
AT_LOCK="/var/lock/modem_at.lock"

log() {
    echo "$(TZ='<+07>-7' date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

LOCK_FILE="/tmp/daily_auto_renew.lock"
exec 201>"$LOCK_FILE"
if ! flock -n 201; then
    exit 0
fi

ACTION="$1"
is_manual=0
no_tg=0
for arg in "$@"; do
    case "$arg" in
        --manual|quick_send|user_intent|--force|renew|--now|1touch|one_touch)
            is_manual=1
            ;;
        --no-tg|--quiet)
            no_tg=1
            ;;
    esac
done

port=$(cat /tmp/master_sms_port 2>/dev/null)
[ -z "$port" ] || [ ! -c "$port" ] && port=$(cat /tmp/custom_at_port 2>/dev/null)
[ -z "$port" ] || [ ! -c "$port" ] && port="/dev/ttyUSB0"
[ ! -c "$port" ] && [ -c "/dev/ttyUSB2" ] && port="/dev/ttyUSB2"

# 1. Dong bo gio truc tiep tu tram phat di dong (Cellular Time Sync)
sync_cell_time() {
    local cur_year=$(TZ='<+07>-7' date +%Y)
    if [ "$cur_year" -lt 2024 ] && [ -c "$port" ] && command -v atinout >/dev/null 2>&1; then
        local raw=$(
            flock -x -w 4 200 || exit 0
            printf 'AT+CCLK?\r\n' | atinout - "$port" - 2>/dev/null | grep '+CCLK:'
        ) 200>"$AT_LOCK"
        local clean=$(echo "$raw" | tr -d '"+')
        local val=$(echo "$clean" | awk '{print $2}')
        if [ -n "$val" ]; then
            local dt=$(echo "$val" | cut -d',' -f1)
            local tm=$(echo "$val" | cut -d',' -f2 | cut -c1-8)
            local y=$(echo "$dt" | cut -d'/' -f1)
            local m=$(echo "$dt" | cut -d'/' -f2)
            local d=$(echo "$dt" | cut -d'/' -f3)
            if [ -n "$y" ] && [ -n "$m" ] && [ -n "$d" ] && [ -n "$tm" ]; then
                date -u -s "20${y}-${m}-${d} ${tm}" >/dev/null 2>&1
                log "Đồng bộ giờ thực từ trạm phát sóng di động: 20${y}-${m}-${d} ${tm} UTC"
            fi
        fi
    fi
}
sync_cell_time

# 2. Xac dinh SIM hien tai tu phan cung thuc te (Modem AT Port)
cur_iccid=$(cat /tmp/sms_current_iccid /tmp/current_sim_iccid 2>/dev/null | grep -oE '[0-9]{18,22}' | head -1)
if [ -z "$cur_iccid" ] && [ -c "$port" ] && command -v atinout >/dev/null 2>&1; then
    cur_iccid=$(
        flock -x -w 4 200 || exit 0
        printf 'AT+ICCID\r\n' | atinout - "$port" - 2>/dev/null | grep -oE '[0-9]{18,22}' | head -1
    ) 200>"$AT_LOCK"
    [ -n "$cur_iccid" ] && echo "$cur_iccid" > /tmp/sms_current_iccid
fi

# 3. Kiem tra Whitelist: Kiem thuc bang ma bam mat ma hoc SHA-256 (Zero Leak)
DEFAULT_ICCID_HASHES="a7a16520a4144e79d6b262ce4265a5d585154221b52803d8e8e6b62213e49865 c317b0ec0ee235c2bae6baf0efde7b03a05e35ad84cf794fc71a809802d47df9 e972c309ace289c3037d4479d79b983d02151f3868f003073085abf4bf508575"

is_sim_allowed=0
if [ -n "$cur_iccid" ]; then
    cur_hash=$(printf "%s" "$cur_iccid" | sha256sum | awk '{print $1}')
    for h in $DEFAULT_ICCID_HASHES; do
        if [ "$cur_hash" = "$h" ]; then
            is_sim_allowed=1
            break
        fi
    done
    if [ "$is_sim_allowed" -eq 0 ] && [ -f /etc/config/allowed_iccids.dat ]; then
        if grep -qF "$cur_iccid" /etc/config/allowed_iccids.dat 2>/dev/null || grep -qF "$cur_hash" /etc/config/allowed_iccids.dat 2>/dev/null; then
            is_sim_allowed=1
        fi
    fi
fi

masked_cur_iccid="Chưa phát hiện"
if [ -n "$cur_iccid" ] && [ ${#cur_iccid} -ge 10 ]; then
    masked_cur_iccid=$(echo "$cur_iccid" | awk '{print substr($0,1,6) "******" substr($0,length($0)-3)}')
fi

# ==============================================================================
# [QUY CHUAN AN TOAN BAT BIEN CHO ANH DUY - BAO MAT SMS 100%]
# SIM NGOAI DANH MUC MAC DINH: KHOA CHAT 100%, TUYET DOI KHONG LEN LICH, KHONG GUI!
# ==============================================================================
if [ "$is_sim_allowed" -ne 1 ]; then
    rm -f /tmp/daily_renew_schedule.dat /tmp/next_auto_renew_schedule.txt /tmp/next_vip_renew_schedule.txt /tmp/daily_renew_target_time.txt /tmp/sms_custom_send_epoch 2>/dev/null
    echo "LOCKED" > /tmp/master_sim_status
    echo "0" > /tmp/sms_next_send_epoch
    echo "0" > /tmp/sms_next_wake_epoch
    
    if [ "$ACTION" = "--status" ] || [ "$ACTION" = "status" ]; then
        echo "🔒 LỊCH GIA HẠN SMS: ĐÃ KHÓA CHẶT 100% (SIM ngoài danh mục mặc định)"
        echo "Mã SIM: ${masked_cur_iccid} | Không lên lịch gửi bất kỳ tin nhắn nào."
        exit 0
    fi
    if [ "$is_manual" -eq 1 ]; then
        echo "🔒 BẢO VỆ AN TOÀN: PHÁT HIỆN SIM NGOÀI DANH SÁCH (${masked_cur_iccid})!"
        echo "HỆ THỐNG ĐÃ KHÓA TOÀN BỘ TÁC VỤ GỬI SMS ĐỂ TRÁNH MẤT TIỀN NGOÀI Ý MUỐN!"
        exit 1
    fi
    exit 0
fi

# 4. Kiem tra Circuit Breaker (CHỈ ÁP DỤNG KHI CHẠY TỰ ĐỘNG, BỎ QUA KHI THỰC THI THỦ CÔNG)
today=$(TZ='<+07>-7' date '+%Y-%m-%d')
LAST_SENT_FILE="/etc/config/sim_last_sent.dat"
if [ "$is_manual" -ne 1 ]; then
    if [ -f "$LAST_SENT_FILE" ]; then
        last_sent_date=$(cut -d'|' -f1 "$LAST_SENT_FILE" 2>/dev/null | tr -d ' \r\n')
        if [ "$last_sent_date" = "$today" ]; then
            touch "/tmp/sms_scheduled_sent_$today"
            exit 0
        fi
    fi
fi

# 5. Tinh toan lich gui cho the SIM hop le
custom_time=$(cat /etc/config/sms_custom_time.dat 2>/dev/null | tr -d ' \r\n')
[ -z "$custom_time" ] && custom_time="01:25:30"
t_h=$(echo "$custom_time" | cut -d':' -f1)
t_m=$(echo "$custom_time" | cut -d':' -f2)
t_s=$(echo "$custom_time" | cut -d':' -f3)
[ -z "$t_s" ] && t_s="00"

total_sec=$(( t_h*3600 + t_m*60 + t_s ))
if [ "$total_sec" -lt 1200 ] || [ "$total_sec" -gt 20400 ]; then
    t_h=1; t_m=25; t_s=30
    custom_time="01:25:30"
fi

today_midnight=$(TZ='<+07>-7' date -d "${today} 00:00:00" +%s 2>/dev/null || date +%s)
target_epoch=$(( today_midnight + t_h*3600 + t_m*60 + t_s ))
target_hhmmss="$custom_time"
echo "${today}|${target_epoch}|${target_hhmmss}" > /tmp/daily_renew_schedule.dat
echo "${target_hhmmss} ngày ${today}" > /tmp/next_auto_renew_schedule.txt
echo "${target_hhmmss} ngày ${today}" > /tmp/next_vip_renew_schedule.txt 2>/dev/null

# Cu phap goi cuoc tuy chinh tu nguoi dung hoac mac dinh 5G150N
renew_pkg=$(cat /etc/config/sms_renew_package.dat 2>/dev/null | tr -d ' \r\n')
[ -z "$renew_pkg" ] && renew_pkg="5G150N"
renew_dest=$(cat /etc/config/sms_renew_dest.dat 2>/dev/null | tr -d ' \r\n')
[ -z "$renew_dest" ] && renew_dest="191"

if [ "$ACTION" = "--status" ] || [ "$ACTION" = "status" ]; then
    echo "🟢 LỊCH GIA HẠN TỰ ĐỘNG (${masked_cur_iccid}):"
    echo "Giờ gửi: ${target_hhmmss} | Cú pháp: ${renew_pkg} gửi ${renew_dest}"
    exit 0
fi

if [ "$is_manual" -ne 1 ]; then
    now_epoch=$(date +%s)
    if [ "$now_epoch" -lt "$target_epoch" ]; then
        exit 0
    fi
fi

# ==============================================================================
# 6. QUY TRÌNH GIA HẠN & ĐỔI IP THEO LỆNH CHUẨN CỦA ANH DUY:
# 1. Gửi cú pháp gói cước (mặc định 5G150N) tới tổng đài
# 2. Sau 2s gửi xác nhận Y tới tổng đài
# 3. Khởi động ấm Baseband (Warm Reset AT+CFUN=1,1 / AT!RESET) giải phóng 100% RAM rác & DMA
# 4. Tái gắn kết sóng di động và nhận IP WAN mới sạch sẽ
# ==============================================================================
log "⚡ [Pha 1/4] Gửi SMS cú pháp [${renew_pkg}] tới tổng đài [${renew_dest}]..."
touch /tmp/sms_sending.lock

run_send_sms() {
    local dest="$1"
    local text="$2"
    (
        flock -x -w 8 200 || exit 1
        if command -v modem_lock_run >/dev/null 2>&1; then
            modem_lock_run sms_tool -d "$port" send "$dest" "$text" >/dev/null 2>&1
        else
            sms_tool -d "$port" send "$dest" "$text" >/dev/null 2>&1
        fi
    ) 200>"$AT_LOCK"
}

run_send_sms "$renew_dest" "$renew_pkg"
log "✔️ [Pha 1/4] Đã gửi [${renew_pkg}] tới [${renew_dest}]. Chờ 2 giây..."
sleep 2

# Pha 2: Sau 2s gửi Y tới 191
log "⚡ [Pha 2/4] Gửi tin nhắn xác nhận [Y] tới tổng đài [${renew_dest}]..."
run_send_sms "$renew_dest" "Y"
log "✔️ [Pha 2/4] Đã gửi xác nhận [Y] tới [${renew_dest}]. Chờ 5 giây..."
sleep 5
rm -f /tmp/sms_sending.lock

# Pha 3: Khởi động ấm Baseband (Clean Warm Reset) giải phóng rác DMA PCIe và RAM modem
log "⚡ [Pha 3/4] KHỞI ĐỘNG LẠI CARD WWAN (Warm Reset AT+CFUN=1,1 / AT!RESET) để xả sạch RAM rác, bộ nhớ đệm DMA PCIe và PDP context..."
if [ -c "$port" ]; then
    local m_type=$(cat /tmp/master_m_type 2>/dev/null || lsusb 2>/dev/null)
    (
        flock -x -w 5 200 || exit 0
        if echo "$m_type" | grep -iqE "sierra|1199:" || lspci 2>/dev/null | grep -iqE "17cb:0306|sdx55"; then
            printf 'AT!RESET\r\n' | atinout - "$port" - >/dev/null 2>&1 || printf 'AT+CFUN=1,1\r\n' | atinout - "$port" - >/dev/null 2>&1
        elif echo "$m_type" | grep -iqE "fibocom|1e0e:|2cb7:"; then
            printf 'AT+CFUN=15\r\n' | atinout - "$port" - >/dev/null 2>&1 || printf 'AT+CFUN=1,1\r\n' | atinout - "$port" - >/dev/null 2>&1
        else
            printf 'AT+CFUN=1,1\r\n' | atinout - "$port" - >/dev/null 2>&1
        fi
    ) 200>"$AT_LOCK"
fi
log "⏳ [Pha 3/4] Chờ 14 giây để chip baseband hoàn tất tái sinh hệ điều hành nội bộ..."
sleep 14

# Pha 4: Tái kích hoạt interface mạng để nhận IP WAN mới tức thì
log "📶 [Pha 4/4] Tái kích hoạt interface 5G và nhận IP WAN mới sạch sẽ..."
for w_dev in $(seq 1 12); do
    [ -e "/dev/cdc-wdm0" ] || [ -e "/dev/wwan0qmi0" ] || [ -e "/dev/ttyUSB0" ] && break
    sleep 1
done

( ifup duydoan_5g 2>/dev/null || ifup wwan 2>/dev/null || ifup wan 2>/dev/null ) >/dev/null 2>&1 &
sleep 6

new_ip=$(ip -4 addr show wwan0 2>/dev/null | grep -oE 'inet [0-9.]+' | head -1 | cut -d' ' -f2)
[ -z "$new_ip" ] && new_ip=$(ip -4 addr show eth2 2>/dev/null | grep -oE 'inet [0-9.]+' | head -1 | cut -d' ' -f2)
[ -z "$new_ip" ] && new_ip=$(ip -4 addr show usb0 2>/dev/null | grep -oE 'inet [0-9.]+' | head -1 | cut -d' ' -f2)
[ -z "$new_ip" ] && new_ip=$(ip -4 addr show mhi_hwip0 2>/dev/null | grep -oE 'inet [0-9.]+' | head -1 | cut -d' ' -f2)
log "🎯 [Hoàn tất] Modem đã tái kết nối sóng thành công! IP WAN mới: ${new_ip:-Đang đàm phán DHCP...}"

# Ghi nhớ Circuit Breaker
echo "${today}|${target_epoch}|${renew_pkg}" > "$LAST_SENT_FILE"
touch "/tmp/sms_scheduled_sent_$today"
echo "{\"status\":\"sent\",\"package\":\"$renew_pkg\",\"dest\":\"$renew_dest\",\"time\":\"$(TZ='<+07>-7' date '+%H:%M:%S %d/%m/%Y')\",\"target_time\":\"$target_hhmmss\",\"new_ip\":\"${new_ip:-Mới}\"}" > /tmp/last_renew_success.json
sync
log "🎯 Chu kỳ gia hạn và đổi IP ngày $today đã hoàn tất xuất sắc."
exit 0
