#!/bin/sh
# Auto-sync SMS for PCIe / QModem WWAN cards into LuCI inbox format

q_modem_id=$(uci -q get qmodem.main.modem_default 2>/dev/null || uci -q show qmodem | grep -m1 '=modem-device' | cut -d'.' -f2 | cut -d'=' -f1 || echo "0000_01_00_0")
q_out=$(ubus call qmodem.sms list "{\"modem_id\":\"$q_modem_id\"}" 2>/dev/null || ubus call qmodem.sms list 2>/dev/null)

combined=""
if [ -n "$q_out" ]; then
    for idx in $(seq 0 50); do
        sender=$(echo "$q_out" | jsonfilter -e "@.messages[$idx].sender" 2>/dev/null)
        [ -z "$sender" ] && continue
        content=$(echo "$q_out" | jsonfilter -e "@.messages[$idx].content" 2>/dev/null)
        [ -z "$content" ] && continue
        ts=$(echo "$q_out" | jsonfilter -e "@.messages[$idx].timestamp" 2>/dev/null)
        time_str=""
        if [ -n "$ts" ] && [ "$ts" -gt 0 ] 2>/dev/null; then
            time_str=" ($(date -d "@$ts" '+%d/%m/%Y %H:%M:%S' 2>/dev/null || date -r "$ts" '+%d/%m/%Y %H:%M:%S' 2>/dev/null))"
        fi
        [ -n "$combined" ] && combined="${combined}\n\n"
        combined="${combined}[ Tin nhắn từ ${sender}${time_str} ]:\n${content}"
    done
fi

if [ -n "$combined" ]; then
    formatted_json=$(printf "%b" "$combined" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
    printf '"%s"' "$formatted_json" > /tmp/sms_inbox.json
else
    printf '"%s"' "Hộp thư trống hoặc chưa có tin nhắn mới trên modem PCIe." > /tmp/sms_inbox.json
fi
chmod 644 /tmp/sms_inbox.json 2>/dev/null
