#!/usr/bin/lua
-- DOANDUY 5G PCIe SMS Reader & Decoder Engine (QMI WMS + UCS2 UTF-8)
-- Invariant: Fast, Non-blocking, Concatenated SMS Reassembly
local nixio = require("nixio")

local dev = "/dev/wwan0qmi0"
if not nixio.fs.stat(dev) then
    dev = "/dev/cdc-wdm0"
end

local function ucs2_to_utf8(hex)
    if not hex or #hex < 4 then return hex or "" end
    local res = {}
    for i = 1, #hex, 4 do
        local cp = tonumber(hex:sub(i, i+3), 16)
        if cp then
            if cp < 0x80 then
                table.insert(res, string.char(cp))
            elseif cp < 0x800 then
                table.insert(res, string.char(0xC0 + math.floor(cp / 64), 0x80 + (cp % 64)))
            elseif cp < 0x10000 then
                table.insert(res, string.char(
                    0xE0 + math.floor(cp / 4096),
                    0x80 + math.floor((cp % 4096) / 64),
                    0x80 + (cp % 64)
                ))
            end
        end
    end
    return table.concat(res)
end

-- Safely pause quectel-CM-M briefly so uqmi can query QMI without race conditions
os.execute("killall -STOP quectel-CM-M quectel-CM 2>/dev/null")

local raw_messages = {}
local storages = {"me", "sim"}

for _, st in ipairs(storages) do
    local h = io.popen(string.format("uqmi -s -t 2500 -d %s --storage %s --list-messages 2>/dev/null", dev, st))
    if h then
        local out = h:read("*a") or ""
        h:close()
        out = out:gsub("%[", ""):gsub("%]", ""):gsub("%s+", "")
        if #out > 0 then
            for id in out:gmatch("%d+") do
                local h_msg = io.popen(string.format("uqmi -s -t 2000 -d %s --storage %s --get-message %s 2>/dev/null", dev, st, id))
                if h_msg then
                    local json_str = h_msg:read("*a") or ""
                    h_msg:close()
                    if json_str:find('"sender"') then
                        local sender = json_str:match('"sender"%s*:%s*"([^"]*)"') or "Tổng Đài"
                        local ts = json_str:match('"timestamp"%s*:%s*"([^"]*)"') or ""
                        local text = json_str:match('"text"%s*:%s*"([^"]*)"')
                        local ucs2 = json_str:match('"ucs%-2"%s*:%s*"([^"]*)"')
                        local ref = json_str:match('"concat_ref"%s*:%s*(%d+)')
                        local part = json_str:match('"concat_part"%s*:%s*(%d+)')
                        local parts = json_str:match('"concat_parts"%s*:%s*(%d+)')
                        
                        local body = ""
                        if ucs2 and #ucs2 > 0 then
                            body = ucs2_to_utf8(ucs2)
                        elseif text and #text > 0 then
                            body = text:gsub("\\n", "\n"):gsub("\\r", ""):gsub('\\"', '"'):gsub("\\\\", "\\")
                        end
                        
                        table.insert(raw_messages, {
                            id = tonumber(id),
                            storage = st,
                            sender = sender:gsub("@", ""),
                            timestamp = ts,
                            body = body,
                            ref = ref and tonumber(ref) or nil,
                            part = part and tonumber(part) or nil,
                            parts = parts and tonumber(parts) or nil
                        })
                    end
                end
            end
        end
    end
end

-- Resume quectel-CM-M immediately
os.execute("killall -CONT quectel-CM-M quectel-CM 2>/dev/null")

-- Group multi-part messages
local grouped = {}
local final_list = {}

for _, msg in ipairs(raw_messages) do
    if msg.ref and msg.parts and msg.parts > 1 then
        local key = msg.sender .. "_" .. tostring(msg.ref)
        if not grouped[key] then
            grouped[key] = {
                sender = msg.sender,
                timestamp = msg.timestamp,
                parts = {}
            }
        end
        grouped[key].parts[msg.part or 1] = msg.body
    else
        table.insert(final_list, {
            sender = msg.sender,
            timestamp = msg.timestamp,
            body = msg.body
        })
    end
end

for key, g in pairs(grouped) do
    local full_body = {}
    local max_p = #g.parts
    for i = 1, 10 do
        if g.parts[i] then table.insert(full_body, g.parts[i]) end
    end
    table.insert(final_list, {
        sender = g.sender,
        timestamp = g.timestamp,
        body = table.concat(full_body)
    })
end

-- Sort newest first
table.sort(final_list, function(a, b)
    return (a.timestamp or "") > (b.timestamp or "")
end)

local formatted = {}
for i, m in ipairs(final_list) do
    table.insert(formatted, string.format("[ Tin nhắn #%d từ %s (%s) ]:\n%s", i, m.sender, m.timestamp, m.body))
end

local out_f = io.open("/tmp/sms_inbox.json", "w")
if out_f then
    if #formatted > 0 then
        local combined = table.concat(formatted, "\n\n")
        local esc = combined:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\r', ''):gsub('\n', '\\n')
        out_f:write('"' .. esc .. '"')
    else
        out_f:write('"Hộp thư trống hoặc chưa có tin nhắn mới."')
    end
    out_f:close()
end
