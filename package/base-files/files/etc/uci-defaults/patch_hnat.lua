local function replace_plain(str, target, repl)
    local s, e = string.find(str, target, 1, true)
    if not s then return str, false end
    return string.sub(str, 1, s - 1) .. repl .. string.sub(str, e + 1), true
end

local function replace_all_plain(str, target, repl)
    local count = 0
    local pos = 1
    while true do
        local s, e = string.find(str, target, pos, true)
        if not s then break end
        str = string.sub(str, 1, s - 1) .. repl .. string.sub(str, e + 1)
        pos = s + #repl
        count = count + 1
    end
    return str, count
end

local function patch_file(path, fn)
    local f = io.open(path, "r")
    if not f then
        print("SKIP (not found): " .. path)
        return
    end
    local content = f:read("*a")
    f:close()
    local new_content, changed = fn(content)
    if changed then
        local wf = io.open(path, "w")
        wf:write(new_content)
        wf:close()
        print("PATCHED: " .. path)
    else
        print("ALREADY PATCHED or NO MATCH: " .. path)
    end
end

local function patch_fast_stats(c)
    local ch = false
    local t1 = [[    if [ "$ppe_cnt" -gt 0 ]; then
        HW_ACCEL_INFO="PPE HW: ${ppe_cnt} luồng • Conntrack: ${mtk_cnt} luồng"
    else
        HW_ACCEL_INFO="Flow Offload: Bật • Conntrack: ${mtk_cnt} luồng"
    fi]]
    local r1 = [[    hw_off_cfg=$(uci -q get firewall.@defaults[0].flow_offloading_hw 2>/dev/null || echo "1")
    if [ -f /etc/config/hnat_disabled ] || [ "$hw_off_cfg" = "0" ]; then
        HNAT_ENABLED="0"
        HW_ACCEL_INFO="PPE HW: Đã tắt • Conntrack: ${mtk_cnt} luồng"
    else
        HNAT_ENABLED="1"
        if [ "$ppe_cnt" -gt 0 ]; then
            HW_ACCEL_INFO="PPE HW: ${ppe_cnt} luồng • Conntrack: ${mtk_cnt} luồng"
        else
            HW_ACCEL_INFO="Flow Offload: Bật • Conntrack: ${mtk_cnt} luồng"
        fi
    fi]]
    if not string.find(c, "HNAT_ENABLED=", 1, true) then
        local nc, ok1 = replace_plain(c, t1, r1)
        if ok1 then c = nc; ch = true end
    end
    local t2 = [[  "ppe_conns": "${PPE_CONNS:-0}",]]
    local r2 = [[  "ppe_conns": "${PPE_CONNS:-0}",
  "hnat_enabled": ${HNAT_ENABLED:-1},]]
    if not string.find(c, '"hnat_enabled":', 1, true) then
        local nc, ok2 = replace_plain(c, t2, r2)
        if ok2 then c = nc; ch = true end
    end
    return c, ch
end

local function patch_rpcd(c)
    local ch = false
    local t1 = [["toggleAllScript":{"action":"string"},"getAllScriptStatus":{}}' ;;]]
    local r1 = [["toggleAllScript":{"action":"string"},"getAllScriptStatus":{},"toggleHNAT":{"action":"string"}}' ;;]]
    if not string.find(c, '"toggleHNAT":', 1, true) then
        local nc, ok1 = replace_plain(c, t1, r1)
        if ok1 then c = nc; ch = true end
    end
    local t2 = [[            toggleAllScript)]]
    local r2 = [[            toggleHNAT)
                act=$(echo "$input" | jsonfilter -e '$.action' 2>/dev/null || echo "on")
                if [ "$act" = "off" ] || [ "$act" = "0" ] || [ "$act" = "disable" ]; then
                    touch /etc/config/hnat_disabled
                    uci -q set firewall.@defaults[0].flow_offloading='0'
                    uci -q set firewall.@defaults[0].flow_offloading_hw='0'
                    uci commit firewall 2>/dev/null
                    for wed_p in /sys/module/mt76/parameters/wed_offload /sys/module/mt7915e/parameters/wed_offload; do
                        [ -w "$wed_p" ] && echo 0 > "$wed_p" 2>/dev/null
                    done
                    ( /etc/init.d/firewall reload >/dev/null 2>&1; [ -x /usr/bin/fast_stats_fetcher.sh ] && /usr/bin/fast_stats_fetcher.sh >/dev/null 2>&1 ) &
                    printf '{"success":true,"hnat_enabled":0,"message":"🛑 Đã TẮT MediaTek PPE HNAT (Chế độ CPU thuần / Tương thích 100%% VPN, PassWall & QoS)"}\n'
                else
                    rm -f /etc/config/hnat_disabled
                    uci -q set firewall.@defaults[0].flow_offloading='1'
                    uci -q set firewall.@defaults[0].flow_offloading_hw='1'
                    uci commit firewall 2>/dev/null
                    for wed_p in /sys/module/mt76/parameters/wed_offload /sys/module/mt7915e/parameters/wed_offload; do
                        [ -w "$wed_p" ] && echo 1 > "$wed_p" 2>/dev/null
                    done
                    ( /etc/init.d/firewall reload >/dev/null 2>&1; [ -x /usr/bin/fast_stats_fetcher.sh ] && /usr/bin/fast_stats_fetcher.sh >/dev/null 2>&1 ) &
                    printf '{"success":true,"hnat_enabled":1,"message":"⚡ Đã BẬT MediaTek PPE Hardware NAT + WED Turbo!"}\n'
                fi
                ;;
            toggleAllScript)]]
    if not string.find(c, "toggleHNAT)", 1, true) then
        local nc, ok2 = replace_plain(c, t2, r2)
        if ok2 then c = nc; ch = true end
    end
    return c, ch
end

local function patch_weather_js(c)
    local ch = false
    local t1 = [[var callToggleAllScript = rpc.declare({ object: 'luci.weather-status', method: 'toggleAllScript', params: ['action'], expect: { } });]]
    local r1 = [[var callToggleHNAT = rpc.declare({ object: 'luci.weather-status', method: 'toggleHNAT', params: ['action'], expect: { } });
var callToggleAllScript = rpc.declare({ object: 'luci.weather-status', method: 'toggleAllScript', params: ['action'], expect: { } });]]
    if not string.find(c, "callToggleHNAT", 1, true) then
        local nc, cnt = replace_all_plain(c, t1, r1)
        if cnt > 0 then c = nc; ch = true end
    end

    local t2 = [[        if (isMtkCur) {
            var elPpe = document.getElementById('ppe-conns-val');
            var ppeVal = parseInt(f.ppe_conns || '0');
            if (elPpe) elPpe.textContent = ppeVal > 0 ? (ppeVal + ' luồng HW') : 'Hoạt động';
            var elConntrack = document.getElementById('ecm-conns-val');
            if (elConntrack) elConntrack.textContent = ecmConns + ' luồng';
            var elBreakdown = document.getElementById('ecm-proto-breakdown');
            if (elBreakdown) elBreakdown.textContent = ' (TCP ' + ecmTcp + ' / UDP ' + ecmUdp + ')';
        }]]
    local r2 = [[        if (isMtkCur) {
            var isHnatEn = (f.hnat_enabled === undefined || f.hnat_enabled === null) ? true : (String(f.hnat_enabled) !== '0' && f.hnat_enabled !== false);
            var elPpe = document.getElementById('ppe-conns-val');
            var ppeVal = parseInt(f.ppe_conns || '0');
            if (elPpe) elPpe.textContent = !isHnatEn ? 'Đã tắt (CPU/VPN)' : (ppeVal > 0 ? (ppeVal + ' luồng HW') : 'Hoạt động');
            var elBtnHnat = document.getElementById('btn-toggle-hnat-badge');
            if (elBtnHnat && elBtnHnat.textContent.indexOf('⏳') === -1) {
                elBtnHnat.setAttribute('data-enabled', isHnatEn ? '1' : '0');
                elBtnHnat.textContent = isHnatEn ? '🟢 HNAT: BẬT' : '⚪ HNAT: TẮT';
                elBtnHnat.style.background = isHnatEn ? '#dcfce7' : '#f1f5f9';
                elBtnHnat.style.color = isHnatEn ? '#15803d' : '#475569';
                elBtnHnat.style.border = isHnatEn ? '1px solid #86efac' : '1px solid #cbd5e1';
            }
            var elConntrack = document.getElementById('ecm-conns-val');
            if (elConntrack) elConntrack.textContent = ecmConns + ' luồng';
            var elBreakdown = document.getElementById('ecm-proto-breakdown');
            if (elBreakdown) elBreakdown.textContent = ' (TCP ' + ecmTcp + ' / UDP ' + ecmUdp + ')';
        }]]
    if not string.find(c, "btn-toggle-hnat-badge", 1, true) then
        local nc, ok2 = replace_plain(c, t2, r2)
        if ok2 then c = nc; ch = true end

        local t3 = [[        if (isMtk) {
            var ppeVal = (fast && fast.ppe_conns) ? parseInt(fast.ppe_conns) : 0;
            var ppeTxt = ppeVal > 0 ? (ppeVal + ' luồng HW') : 'Hoạt động';
            hwDetailElements = [
                E('span', {}, [
                    'PPE HW: ',
                    E('b', { id: 'ppe-conns-val', style: 'color: #000000;' }, ppeTxt)
                ]),
                E('span', { style: 'color: #000000;' }, ' • '),
                E('span', {}, [
                    'Conntrack: ',
                    E('b', { id: 'ecm-conns-val', style: 'color: #000000;' }, ecmConnsStr + ' luồng'),
                    E('span', { id: 'ecm-proto-breakdown', style: 'color: #000000; font-size: 11px; margin-left: 2px;' }, ' (TCP ' + ecmTcpStr + ' / UDP ' + ecmUdpStr + ')')
                ])
            ];]]
        local r3 = [[        if (isMtk) {
            var isHnatInit = (fast && fast.hnat_enabled !== undefined && fast.hnat_enabled !== null) ? (String(fast.hnat_enabled) !== '0' && fast.hnat_enabled !== false) : true;
            var ppeVal = (fast && fast.ppe_conns) ? parseInt(fast.ppe_conns) : 0;
            var ppeTxt = !isHnatInit ? 'Đã tắt (CPU/VPN)' : (ppeVal > 0 ? (ppeVal + ' luồng HW') : 'Hoạt động');
            hwDetailElements = [
                E('span', {}, [
                    'PPE HW: ',
                    E('b', { id: 'ppe-conns-val', style: 'color: #000000;' }, ppeTxt)
                ]),
                E('span', { style: 'color: #000000;' }, ' • '),
                E('span', {}, [
                    'Conntrack: ',
                    E('b', { id: 'ecm-conns-val', style: 'color: #000000;' }, ecmConnsStr + ' luồng'),
                    E('span', { id: 'ecm-proto-breakdown', style: 'color: #000000; font-size: 11px; margin-left: 2px;' }, ' (TCP ' + ecmTcpStr + ' / UDP ' + ecmUdpStr + ')')
                ]),
                E('button', {
                    id: 'btn-toggle-hnat-badge',
                    'data-enabled': isHnatInit ? '1' : '0',
                    title: 'Bấm để Bật / Tắt tăng tốc phần cứng MediaTek PPE HNAT (WED Turbo)',
                    style: 'margin-left: 6px; padding: 2px 10px; border-radius: 14px; font-size: 12px; font-weight: 800; cursor: pointer; transition: all 0.2s; ' +
                           (isHnatInit ? 'background: #dcfce7; color: #15803d; border: 1px solid #86efac;' : 'background: #f1f5f9; color: #475569; border: 1px solid #cbd5e1;'),
                    click: function(ev) {
                        ev.stopPropagation();
                        var btn = document.getElementById('btn-toggle-hnat-badge') || ev.currentTarget;
                        var curOn = btn.getAttribute('data-enabled') === '1';
                        var nextAct = curOn ? 'off' : 'on';
                        btn.textContent = '⏳ Đang chuyển...';
                        callToggleHNAT(nextAct).then(function(res) {
                            var nowOn = (nextAct === 'on');
                            btn.setAttribute('data-enabled', nowOn ? '1' : '0');
                            btn.textContent = nowOn ? '🟢 HNAT: BẬT' : '⚪ HNAT: TẮT';
                            btn.style.background = nowOn ? '#dcfce7' : '#f1f5f9';
                            btn.style.color = nowOn ? '#15803d' : '#475569';
                            btn.style.border = nowOn ? '1px solid #86efac' : '1px solid #cbd5e1';
                            if (window._lastFastStats) window._lastFastStats.hnat_enabled = nowOn ? 1 : 0;
                            var elPpe = document.getElementById('ppe-conns-val');
                            if (elPpe) elPpe.textContent = nowOn ? 'Hoạt động' : 'Đã tắt (CPU/VPN)';
                            ui.addNotification(null, E('p', (res && res.message) ? res.message : (nowOn ? '⚡ Đã BẬT MediaTek PPE HNAT!' : '🛑 Đã TẮT MediaTek PPE HNAT!')), 'info');
                        }).catch(function(err) {
                            btn.textContent = curOn ? '🟢 HNAT: BẬT' : '⚪ HNAT: TẮT';
                            ui.addNotification(null, E('p', '❌ Lỗi: ' + (err.message || err)), 'error');
                        });
                    }
                }, isHnatInit ? '🟢 HNAT: BẬT' : '⚪ HNAT: TẮT')
            ];]]
        local nc3, ok3 = replace_plain(c, t3, r3)
        if ok3 then c = nc3; ch = true end
    end
    return c, ch
end

local function patch_daemons(c)
    local ch = false
    local g1 = [[        sysctl -w net.netfilter.nf_conntrack_tcp_be_liberal=1 >/dev/null 2>&1
        uci set firewall.@defaults[0].flow_offloading='1' 2>/dev/null
        uci set firewall.@defaults[0].flow_offloading_hw='1' 2>/dev/null
        uci commit firewall 2>/dev/null
        ( /etc/init.d/firewall reload >/dev/null 2>&1 & )]]
    local r_g1 = [[        sysctl -w net.netfilter.nf_conntrack_tcp_be_liberal=1 >/dev/null 2>&1
        if [ ! -f /etc/config/hnat_disabled ]; then
            uci set firewall.@defaults[0].flow_offloading='1' 2>/dev/null
            uci set firewall.@defaults[0].flow_offloading_hw='1' 2>/dev/null
            uci commit firewall 2>/dev/null
            ( /etc/init.d/firewall reload >/dev/null 2>&1 & )
        fi]]
    local nc, ok = replace_plain(c, g1, r_g1)
    if ok then c = nc; ch = true end

    local g2 = [[    if [ "$(uci -q get firewall.@defaults[0].flow_offloading)" != "1" ] || [ "$(uci -q get firewall.@defaults[0].flow_offloading_hw)" != "1" ]; then]]
    local r_g2 = [[    if [ ! -f /etc/config/hnat_disabled ] && { [ "$(uci -q get firewall.@defaults[0].flow_offloading)" != "1" ] || [ "$(uci -q get firewall.@defaults[0].flow_offloading_hw)" != "1" ]; }; then]]
    nc, ok = replace_plain(c, g2, r_g2)
    if ok then c = nc; ch = true end

    local g3 = [[    elif [ "$soc_hal" = "mediatek_filogic" ]; then]]
    local r_g3 = [[    elif [ "$soc_hal" = "mediatek_filogic" ] && [ ! -f /etc/config/hnat_disabled ]; then]]
    nc, ok = replace_plain(c, g3, r_g3)
    if ok then c = nc; ch = true end

    local g4 = [[            if [ "$off_hw" != "1" ] || [ "$off_sw" != "1" ]; then]]
    local r_g4 = [[            if [ ! -f /etc/config/hnat_disabled ] && { [ "$off_hw" != "1" ] || [ "$off_sw" != "1" ]; }; then]]
    nc, ok = replace_plain(c, g4, r_g4)
    if ok then c = nc; ch = true end

    return c, ch
end

local target_path = arg[1] or "/root/Duydoan-IPQ-MTK/package/base-files/files/etc/init.d/all"
patch_file(target_path, function(c)
    local ch1, ch2, ch3, ch4
    c, ch1 = patch_fast_stats(c)
    c, ch2 = patch_rpcd(c)
    c, ch3 = patch_weather_js(c)
    c, ch4 = patch_daemons(c)
    return c, (ch1 or ch2 or ch3 or ch4)
end)
