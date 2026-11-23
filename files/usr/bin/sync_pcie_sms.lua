local nixio = require("nixio")

local port = "/dev/wwan0at0"
if nixio.fs.stat("/tmp/custom_at_port") then
    local f = io.open("/tmp/custom_at_port", "r")
    if f then
        local p = f:read("*l")
        f:close()
        if p and #p > 0 and nixio.fs.stat(p) then port = p end
    end
end

if not nixio.fs.stat(port) then
    os.exit(0)
end

local function hex2str(hex)
    local t = {}
    for i = 1, #hex, 2 do
        local byte = tonumber(hex:sub(i, i+1), 16)
        if byte then
            if byte >= 32 and byte <= 126 then
                table.insert(t, string.char(byte))
            elseif byte == 10 or byte == 13 then
                table.insert(t, "\n")
            end
        end
    end
    return table.concat(t)
end

local function execute_at(fd, cmd, timeout_ms)
    fd:write(cmd .. "\r\n")
    local resp = ""
    local waited = 0
    while waited < (timeout_ms or 1200) do
        nixio.nanosleep(0, 40000000) -- 40ms
        waited = waited + 40
        local chunk = fd:read(512)
        if chunk and #chunk > 0 then
            resp = resp .. chunk
            if resp:find("OK\r\n") or resp:find("ERROR\r\n") then
                break
            end
        end
    end
    return resp
end

local fd = nixio.open(port, nixio.open_flags("rdwr", "nonblock"))
if not fd then os.exit(1) end

execute_at(fd, "AT+CMGF=1", 400)
execute_at(fd, 'AT+CPMS="ME","ME","ME"', 400)

local messages = {}
for i = 1, 30 do
    local r = execute_at(fd, "AT+CMGR=" .. i, 600)
    if r and r:find("%+CMGR:") then
        local status, sender, ts = r:match('%+CMGR:%s*"([^"]+)"%s*,%s*"([^"]+)"[^,]*%s*,%s*"([^"]+)"')
        local body = r:match('%+CMGR:[^\r\n]+\r\n(.-)\r\n\r\nOK') or r:match('%+CMGR:[^\r\n]+\r\n(.-)\r\nOK')
        if body then
            body = body:gsub("^%s+", ""):gsub("%s+$", "")
            if body:match("^[0-9A-Fa-f]+$") and #body > 8 then
                local dec = hex2str(body)
                if #dec > 0 then body = dec end
            end
            if sender and sender:match("^[0-9A-Fa-f]+$") and #sender >= 8 and not sender:match("^%d%d%d%d%d%d%d%d+$") then
                local s_dec = hex2str(sender)
                if #s_dec > 0 then sender = s_dec end
            end
            table.insert(messages, string.format("[ Tin nhắn #%d từ %s (%s) ]:\n%s", i, sender or "Unknown", ts or "", body))
        end
    end
end
fd:close()

if #messages > 0 then
    local combined = table.concat(messages, "\n\n")
    -- escape json
    local esc = combined:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\r', ''):gsub('\n', '\\n')
    local out_f = io.open("/tmp/sms_inbox.json", "w")
    if out_f then
        out_f:write('"' .. esc .. '"')
        out_f:close()
    end
else
    local out_f = io.open("/tmp/sms_inbox.json", "w")
    if out_f then
        out_f:write('"Hộp thư trống hoặc chưa có tin nhắn mới."')
        out_f:close()
    end
end
