-- PCIe SMS Reader for Sierra EM9190 / Fibocom / Quectel
-- DOANDUY 5G Systems

local port = "/dev/wwan0at0"
local f_port = io.open("/tmp/master_sms_port", "r")
if f_port then
    local p = f_port:read("*l")
    f_port:close()
    if p and #p > 0 then port = p end
end

-- Ensure PCIe device power is on
os.execute("echo on > /sys/bus/pci/devices/0000:01:00.0/power/control 2>/dev/null")

local function hex2str(hex)
    if not hex or #hex < 2 or (#hex % 2 ~= 0) then return hex end
    local t = {}
    for i = 1, #hex, 2 do
        local b = tonumber(hex:sub(i, i+1), 16)
        if b then
            table.insert(t, string.char(b))
        end
    end
    return table.concat(t)
end

-- Set Text Mode
os.execute(string.format("sms_tool -d %s -D at 'AT+CMGF=1' >/dev/null 2>&1", port))

local messages = {}
for i = 1, 25 do
    local handle = io.popen(string.format("timeout 2 sms_tool -d %s -D at 'AT+CMGR=%d' 2>&1", port, i))
    if handle then
        local out = handle:read("*a") or ""
        handle:close()

        if out:find("%+CMGR:") then
            local sender, ts = out:match('%+CMGR:%s*"[^"]*"%s*,%s*"([^"]*)"[^,]*%s*,%s*"([^"]*)"')
            local body = out:match('%+CMGR:[^\r\n]*[\r\n]+(.-)[\r\n]+OK') or out:match('%+CMGR:[^\r\n]*[\r\n]+(.-)$')
            if body then
                body = body:gsub("^%s+", ""):gsub("%s+$", "")
                -- Decode body if all hex characters
                if body:match("^[0-9A-Fa-f]+$") and #body >= 8 and (#body % 2 == 0) then
                    local dec = hex2str(body)
                    if #dec > 0 then body = dec end
                end
                -- Decode sender if hex ASCII
                if sender and sender:match("^[0-9A-Fa-f]+$") and #sender >= 8 and (#sender % 2 == 0) and not sender:match("^%d%d%d%d%d%d%d%d+$") then
                    local s_dec = hex2str(sender)
                    if #s_dec > 0 then sender = s_dec end
                end
                table.insert(messages, string.format("[ Tin nhắn #%d từ %s (%s) ]:\n%s", i, sender or "Tổng Đài", ts or "", body))
            end
        end
    end
end

local out_f = io.open("/tmp/sms_inbox.json", "w")
if out_f then
    if #messages > 0 then
        local combined = table.concat(messages, "\n\n")
        local esc = combined:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\r', ''):gsub('\n', '\\n')
        out_f:write('"' .. esc .. '"')
    else
        out_f:write('"Hộp thư trống hoặc chưa có tin nhắn mới."')
    end
    out_f:close()
end
