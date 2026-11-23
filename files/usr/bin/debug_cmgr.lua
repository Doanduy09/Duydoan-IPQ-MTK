local nixio = require("nixio")
local fd = nixio.open("/dev/wwan0at0", nixio.open_flags("rdwr", "nonblock"))

local function read_with_timeout(fd, max_wait_ms)
    local data = ""
    local waited = 0
    while waited < max_wait_ms do
        local chunk = fd:read(512)
        if chunk and #chunk > 0 then
            data = data .. chunk
            if data:find("OK\r\n") or data:find("ERROR\r\n") then break end
        else
            nixio.nanosleep(0, 50000000) -- sleep 50ms
            waited = waited + 50
        end
    end
    return data
end

fd:write("AT+CMGF=1\r\n")
local r1 = read_with_timeout(fd, 500)
print("CMGF:", r1)

fd:write("AT+CMGR=1\r\n")
local r2 = read_with_timeout(fd, 1500)
print("CMGR=1:", r2)

fd:close()
