#!/usr/bin/lua
-- High-Performance PCIe QMI/AT SMS Reader & UCS-2 Decoder
-- Designed for Qualcomm SDX55 / Sierra EM9190 / Fibocom / Quectel PCIe WWAN

local nixio = require("nixio")
local json = require("luci.jsonc")

local function ucs2_to_utf8(hex)
    if not hex or #hex < 4 or (#hex % 4 ~= 0) then return hex end
    local res = {}
    for i = 1, #hex, 4 do
        local cp = tonumber(hex:sub(i, i+3), 16)
        if cp then
            if cp < 0x80 then
                table.insert(res, string.char(cp))
            elseif cp < 0x800 then
                table.insert(res, string.char(
                    0xC0 + math.floor(cp / 0x40),
                    0x80 + (cp % 0x40)
                ))
            else
                table.insert(res, string.char(
                    0xE0 + math.floor(cp / 0x1000),
                    0x80 + (math.floor(cp / 0x40) % 0x40),
                    0x80 + (cp % 0x40)
                ))
            end
        end
    end
    return table.concat(res)
end

-- 1. Pause CM daemon atomically so QMI bus is exclusive
os.execute("killall -STOP quectel-CM-M quectel-CM 2>/dev/null")

local all_raw = {}
local storages = { { code = "me", name = "Router (ME)" }, { code = "sim", name = "Thẻ SIM (SM)" } }

for _, st in ipairs(storages) do
    local p = io.popen(string.format("uqmi -s -t 1500 -d /dev/wwan0qmi0 --list-messages --storage %s 2>/dev/null", st.code))
    if p then
        local raw_list = p:read("*a") or ""
        p:close()
        local list = json.parse(raw_list)
        if type(list) == "table" and #list > 0 then
            for _, idx in ipairs(list) do
                local mp = io.popen(string.format("uqmi -s -t 1500 -d /dev/wwan0qmi0 --get-message %s --storage %s 2>/dev/null", tostring(idx), st.code))
                if mp then
                    local raw_msg = mp:read("*a") or ""
                    mp:close()
                    -- uqmi sometimes prepends 'Raw text: ...' before the json
                    local json_str = raw_msg:match("({.*})")
                    if json_str then
                        local m = json.parse(json_str)
                        if m and m.sender then
                            local body = m.text or ""
                            if (not body or #body == 0) and m["ucs-2"] then
                                body = ucs2_to_utf8(m["ucs-2"])
                            end
                            table.insert(all_raw, string.format("[%s]\nMSG: %s\nFrom: %s\nDate/Time: %s%s%s\n%s\n",
                                st.name,
                                tostring(idx),
                                tostring(m.sender):gsub("@", ""),
                                tostring(m.timestamp or ""),
                                m.concat_ref and string.format("\nReference number: %s", tostring(m.concat_ref)) or "",
                                m.concat_part and string.format("\nSMS segment %s of %s", tostring(m.concat_part), tostring(m.concat_parts or 1)) or "",
                                body
                            ))
                        end
                    end
                end
            end
        end
    end
end

-- 2. Resume CM daemon immediately
os.execute("killall -CONT quectel-CM-M quectel-CM 2>/dev/null")

local combined = table.concat(all_raw, "\n")
if #combined == 0 then
    combined = "Hộp thư trống hoặc chưa có tin nhắn mới."
end

local out_f = io.open("/tmp/sms_inbox.json", "w")
if out_f then
    out_f:write(json.stringify(combined))
    out_f:close()
end

print(combined)
