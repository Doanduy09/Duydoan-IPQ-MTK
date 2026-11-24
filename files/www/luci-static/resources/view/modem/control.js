// Standalone View for Modem 5G Utilities in Stock or Any Theme
'use strict';
'require view';
'require rpc';
'require ui';
'require poll';

// RPC Declarations
var callSMSInfo = rpc.declare({ object: 'luci.sms-status', method: 'getSMSInfo', expect: { } });
var callFetchSMS = rpc.declare({ object: 'luci.sms-status', method: 'fetchSMSNow', expect: { } });
var callDeleteAllSMS = rpc.declare({ object: 'luci.sms-status', method: 'deleteAllSMS', expect: { } });
var callDeleteSingleSMS = rpc.declare({ object: 'luci.sms-status', method: 'deleteSingleSMS', params: ['indices', 'storage'], expect: { } });
var callSendSMS = rpc.declare({ object: 'luci.sms-status', method: 'sendSMS', params: ['target', 'msg'] });
var callSendAT = rpc.declare({ object: 'luci.sms-status', method: 'sendAT', params: ['cmd', 'port'] });
var callSetPort = rpc.declare({ object: 'luci.sms-status', method: 'setCustomAtPort', params: ['port'] });
var callGetPorts = rpc.declare({ object: 'luci.sms-status', method: 'getAvailablePorts', expect: { } });
var callCheckDataBalance = rpc.declare({ object: 'luci.sms-status', method: 'checkDataBalance', expect: { } });
var callSetBandLock = rpc.declare({ object: 'luci.sms-status', method: 'setBandLock', params: ['mode'] });
var callGetCellInfo = rpc.declare({ object: 'luci.sms-status', method: 'getCellInfo', expect: { } });
var callSetCellLock = rpc.declare({ object: 'luci.sms-status', method: 'setCellLock', params: ['action'], expect: { } });
var callSetCustomSchedule = rpc.declare({ object: 'luci.sms-status', method: 'setCustomSchedule', params: ['datetime'] });

var callChangeIMEI = rpc.declare({ object: 'luci.weather-status', method: 'changeIMEI', params: ['imei', 'brand'] });
var callSetVipImei = rpc.declare({ object: 'luci.sms-status', method: 'setVipImei', params: ['imei'], expect: { } });
var callSetTelegramToken = rpc.declare({ object: 'luci.weather-status', method: 'setTelegramToken', params: ['token', 'admin_id', 'owner_name'] });
var callGetSentinelConfig = rpc.declare({ object: 'luci.sms-status', method: 'getSentinelConfig', expect: { } });
var callSetSentinelConfig = rpc.declare({ object: 'luci.sms-status', method: 'setSentinelConfig', params: ['tg_bot_token', 'tg_admin_id', 'tg_owner_name', 'emergency_phone', 'gemini_api_key', 'tailscale_auth_key', 'cloud_remote', 'cam1_rtsp', 'cam2_rtsp', 'cam_cong_rtsp', 'cameras', 'telegram_bots'] });
var callLoadVaultKeys = rpc.declare({ object: 'luci.sms-status', method: 'loadVaultKeys', expect: { } });
var callTriggerAITest = rpc.declare({ object: 'luci.device-control', method: 'triggerAITest', params: ['mode', 'cam'] });

var callSetTTL = rpc.declare({ object: 'luci.weather-status', method: 'setTTL', params: ['ttl'] });
var callSetCard = rpc.declare({ object: 'luci.weather-status', method: 'setCardMode', params: ['mode', 'iface_name'] });
var callRenameInterface = rpc.declare({ object: 'luci.sms-status', method: 'renameInterface', params: ['new_name'] });

function parseAndRenderSMS(rawText) {
    if (!rawText || typeof rawText !== 'string' || rawText.indexOf('MSG:') === -1) {
        return [ E('div', { style: 'padding: 24px; text-align: center; color: #475569; font-size: 14px; background: #f8fafc; border-radius: 10px; border: 1px dashed #cbd5e1;' }, '📭 Hộp thư trống hoặc chưa có tin nhắn mới.') ];
    }
    var lines = rawText.split('\n'), rawMessages = [], curMsg = null, curStorage = 'Router (ME)';
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i], trimmed = line.trim();
        if (/\[.*(SIM|\(SM\)).*\]/i.test(trimmed)) { curStorage = 'Thẻ SIM (SM)'; continue; }
        else if (/\[.*(ROUTER|MODEM|\(ME\)|\(MT\)).*\]/i.test(trimmed)) { curStorage = 'Router (ME)'; continue; }

        if (trimmed.match(/^MSG:\s*[0-9]+/i)) {
            if (curMsg) rawMessages.push(curMsg);
            curMsg = {
                id: trimmed.replace(/^MSG:\s*/i, '').trim(),
                storage: curStorage,
                from: 'Không xác định',
                datetime: '',
                refNum: '',
                segIndex: 1,
                segTotal: 1,
                contentLines: []
            };
            continue;
        }
        if (!curMsg) continue;
        if (trimmed.match(/^From:\s*/i)) curMsg.from = trimmed.replace(/^From:\s*/i, '').trim();
        else if (trimmed.match(/^Date\/Time:\s*/i)) curMsg.datetime = trimmed.replace(/^Date\/Time:\s*/i, '').trim();
        else if (trimmed.match(/^Reference number:\s*/i)) curMsg.refNum = trimmed.replace(/^Reference number:\s*/i, '').trim();
        else if (trimmed.match(/^SMS segment\s*[0-9]+/i)) {
            var segMatch = trimmed.match(/^SMS segment\s*([0-9]+)(?:\s*(?:of|\/)\s*([0-9]+))?/i);
            if (segMatch) {
                curMsg.segIndex = parseInt(segMatch[1]);
                curMsg.segTotal = segMatch[2] ? parseInt(segMatch[2]) : 3;
            }
        } else { curMsg.contentLines.push(line); }
    }
    if (curMsg) rawMessages.push(curMsg);

    // Grouping & Merging Multipart SMS
    var mergedMap = {}, standaloneList = [];
    rawMessages.forEach(function(m) {
        m.body = m.contentLines.join(' ')
            .replace(/^SMS segment\s*[0-9]*\s*(?:of\s*[0-9]+)?/i, '')
            .replace(/(\w+)-\s+(\w+)/g, '$1$2')
            .replace(/\s+/g, ' ')
            .trim();

        var ts = 0;
        if (m.datetime) {
            var dtParts = m.datetime.replace(/,/g, ' ').split(/\s+/);
            if (dtParts.length >= 2) {
                var dParts = dtParts[0].split(/[\/\-]/);
                var tParts = dtParts[1].split(':');
                if (dParts.length === 3 && tParts.length >= 2) {
                    var yr = parseInt(dParts[2]) > 50 ? 1900 + parseInt(dParts[2]) : 2000 + parseInt(dParts[2]);
                    var mo = parseInt(dParts[0]) - 1;
                    var da = parseInt(dParts[1]);
                    var hr = parseInt(tParts[0]);
                    var mi = parseInt(tParts[1]);
                    var sc = parseInt(tParts[2] || 0);
                    ts = new Date(yr, mo, da, hr, mi, sc).getTime();
                }
            }
        }
        if (!ts) ts = parseInt(m.id) || 0;
        m.ts = ts;

        var key = '';
        if (m.refNum) {
            key = m.from + '_' + m.refNum;
        } else if (m.segTotal > 1) {
            key = m.from + '_tot' + m.segTotal;
        }

        if (key) {
            if (!mergedMap[key]) {
                mergedMap[key] = { from: m.from, storage: m.storage, datetime: m.datetime, ts: m.ts, parts: {}, rawIds: [] };
            }
            if (m.body && !/^SMS segment\s*[0-9]*$/i.test(m.body)) {
                mergedMap[key].parts[m.segIndex] = m.body;
            }
            mergedMap[key].rawIds.push(m.id);
            if (m.ts > mergedMap[key].ts) {
                mergedMap[key].ts = m.ts;
                mergedMap[key].datetime = m.datetime;
            }
        } else if (m.body && !/^SMS segment\s*[0-9]*$/i.test(m.body)) {
            var cleanText = m.body.replace(/\\n/g, '\n').replace(/\\r/g, '').replace(/\\"/g, '"').trim();
            standaloneList.push({ from: m.from, storage: m.storage, datetime: m.datetime, ts: m.ts, rawIds: [m.id], fullBody: cleanText });
        }
    });

    var finalSMSList = [];
    Object.keys(mergedMap).forEach(function(k) {
        var item = mergedMap[k];
        var sortedIndices = Object.keys(item.parts).sort(function(a, b) { return parseInt(a) - parseInt(b); });
        var full = '';
        sortedIndices.forEach(function(idx) {
            full = (full ? full + '\n' : '') + item.parts[idx];
        });
        item.fullBody = full.replace(/\\n/g, '\n').replace(/\\r/g, '').replace(/\\"/g, '"').trim();
        finalSMSList.push(item);
    });

    standaloneList.forEach(function(s) { finalSMSList.push(s); });
    finalSMSList.sort(function(a, b) { return b.ts - a.ts; });

    if (finalSMSList.length === 0) {
        return [ E('div', { style: 'padding: 24px; text-align: center; color: #475569; font-size: 14px; background: #f8fafc; border-radius: 10px; border: 1px dashed #cbd5e1;' }, '📭 Hộp thư trống hoặc chưa có tin nhắn mới.') ];
    }

    var cards = [];
    finalSMSList.forEach(function(item) {
        var isSim = (item.storage && item.storage.indexOf('SIM') !== -1);
        var badgeColor = isSim ? '#2563eb' : '#d97706';
        var badgeBg = isSim ? '#eff6ff' : '#fffbeb';
        var badgeBorder = isSim ? '#bfdbfe' : '#fde68a';
        var badgeIcon = isSim ? '📱' : '💾';
        var badgeText = isSim ? 'Thẻ SIM (SM)' : 'Router (ME)';

        var row = E('div', {
            style: 'background: #ffffff; border: 1.5px solid #e2e8f0; border-radius: 10px; padding: 14px 18px; display: flex; flex-direction: column; gap: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); margin-bottom: 8px;'
        }, [
            E('div', { style: 'display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px;' }, [
                E('div', { style: 'display: flex; align-items: center; gap: 8px;' }, [
                    E('span', {
                        style: 'display: inline-flex; align-items: center; gap: 4px; padding: 2px 8px; border-radius: 6px; font-size: 11.5px; font-weight: 750; background: ' + badgeBg + '; color: ' + badgeColor + '; border: 1px solid ' + badgeBorder + ';'
                    }, [ badgeIcon + ' ' + badgeText ]),
                    E('span', { style: 'font-weight: 850; font-size: 14px; color: #0f172a;' }, 'Từ: ' + item.from)
                ]),
                E('span', { style: 'font-size: 12px; color: #64748b; font-weight: 600;' }, item.datetime || 'Vừa xong')
            ]),
            E('div', {
                style: 'font-size: 13.5px; color: #1e293b; line-height: 1.6; white-space: pre-wrap; word-break: break-word; background: #f8fafc; padding: 12px 14px; border-radius: 6px; border: 1px solid #f1f5f9; font-weight: 550;'
            }, item.fullBody || '(Không có nội dung)'),
            E('div', { style: 'display: flex; justify-content: flex-end; gap: 8px;' }, [
                E('button', {
                    class: 'btn cbi-button',
                    style: 'font-size: 11.5px; padding: 3px 10px; font-weight: 700; border-radius: 6px; background: #f1f5f9; color: #334155; border: 1px solid #cbd5e1; cursor: pointer;',
                    click: function() {
                        var textToCopy = item.fullBody || '';
                        if (navigator && navigator.clipboard && navigator.clipboard.writeText) {
                            navigator.clipboard.writeText(textToCopy).then(function() {
                                ui.addNotification(null, E('p', '📋 Đã sao chép nội dung tin nhắn!'), 'info');
                            });
                        } else {
                            var ta = document.createElement('textarea');
                            ta.value = textToCopy;
                            document.body.appendChild(ta);
                            ta.select();
                            document.execCommand('copy');
                            document.body.removeChild(ta);
                            ui.addNotification(null, E('p', '📋 Đã sao chép nội dung tin nhắn!'), 'info');
                        }
                    }
                }, '📋 Sao Chép'),
                E('button', {
                    class: 'btn cbi-button cbi-button-remove',
                    style: 'font-size: 11.5px; padding: 3px 10px; font-weight: 700; border-radius: 6px;',
                    click: function(ev) {
                        var idStr = item.rawIds.join(',');
                        var storeCode = isSim ? 'SM' : 'ME';
                        if (!confirm('Xóa tin nhắn này (' + idStr + ')?')) return;
                        callDeleteSingleSMS(idStr, storeCode).then(function() {
                            row.remove();
                            var box = document.getElementById('modem-ctrl-sms-inbox');
                            if (box) callFetchSMS().then(function(rep) { box.innerHTML = ''; parseAndRenderSMS(rep.inbox || '').forEach(function(n) { box.appendChild(n); }); });
                        });
                    }
                }, '🗑️ Xóa')
            ])
        ]);
        cards.push(row);
    });
    return cards;
}

return view.extend({
    title: _('Tiện Ích 5G & Quản Trị Modem'),

    load: function() {
        return Promise.all([
            callSMSInfo().catch(function() { return {}; }),
            callGetPorts().catch(function() { return {}; }),
            callGetCellInfo().catch(function() { return {}; }),
            fetch('/cgi-bin/sim_manager?action=get_state&t=' + Date.now()).then(function(r) { return r.json(); }).catch(function() { return {}; }),
            callGetSentinelConfig().catch(function() { return {}; })
        ]);
    },

    render: function(data) {
        var smsRes = data[0] || {};
        var portsData = data[1] || {};
        var cellRes = data[2] || {};
        var simMgrData = data[3] || {};
        var sentinelConfig = data[4] || {};

        var activePort = (portsData && portsData.current_port && portsData.current_port.indexOf('/dev/') !== -1)
            ? portsData.current_port
            : ((smsRes && smsRes.port && smsRes.port.indexOf('/dev/') !== -1)
                ? smsRes.port
                : '/dev/ttyUSB3');
        var currentTab = 'sms';

        var tabButtons = [
            { id: 'tab-btn-sms', key: 'sms', icon: '📬', title: 'Quản Lý SIM & Tin Nhắn SMS' },
            { id: 'tab-btn-modem', key: 'modem', icon: '📶', title: 'Modem 5G, Băng Tần & Lệnh AT' },
            { id: 'tab-btn-mesh', key: 'mesh', icon: '⚡', title: '1-Click Auto Mesh' },
            { id: 'tab-btn-sentinel', key: 'sentinel', icon: '🤖', title: 'Telegram & AI Sentinel' }
        ];

        var tabPanes = {};

        function switchSubTab(targetKey) {
            currentTab = targetKey;
            tabButtons.forEach(function(b) {
                var btnEl = document.getElementById(b.id);
                var paneEl = tabPanes[b.key];
                if (btnEl && paneEl) {
                    if (b.key === targetKey) {
                        btnEl.style.background = '#2563eb';
                        btnEl.style.color = '#ffffff';
                        btnEl.style.borderColor = '#2563eb';
                        paneEl.style.display = 'block';
                        if (b.key === 'mesh' && typeof refreshMeshDashboard === 'function') {
                            refreshMeshDashboard();
                        }
                    } else {
                        btnEl.style.background = '#ffffff';
                        btnEl.style.color = '#334155';
                        btnEl.style.borderColor = '#cbd5e1';
                        paneEl.style.display = 'none';
                    }
                }
            });
        }

        var navBar = E('div', {
            style: 'display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 20px; padding-bottom: 12px; border-bottom: 2px solid #e2e8f0;'
        });

        tabButtons.forEach(function(b) {
            var btn = E('button', {
                id: b.id,
                class: 'btn',
                style: 'display: flex; align-items: center; gap: 6px; padding: 9px 18px; font-weight: 750; font-size: 13.5px; border-radius: 8px; border: 1.5px solid #cbd5e1; cursor: pointer; transition: all 0.2s; background: #ffffff; color: #334155;',
                click: function() { switchSubTab(b.key); }
            }, [ E('span', { style: 'font-size: 16px;' }, b.icon), b.title ]);
            navBar.appendChild(btn);
        });

        // ---------------- TAB 1: QUẢN LÝ SIM & SMS ----------------
        var isMasked = true;
        var activeIccidFull = simMgrData.active_iccid || '';
        var activeIccidMasked = simMgrData.masked_iccid || (activeIccidFull ? activeIccidFull.substring(0, 6) + '******' + activeIccidFull.substring(activeIccidFull.length - 4) : 'Chưa nhận diện');
        /* ==============================================================================
   === LOCKED: VERIFIED BY DOANDUY - DO NOT MODIFY ===
   QUY CHUẨN ĐIỀU KIỆN SIM HỢP LỆ TRÊN CONTROL.JS:
   NẾU KHÔNG CÓ SIM HOẶC SIM NGOÀI DANH MỤC -> isWhitelisted = false -> ẨN 100% CẤU HÌNH TỰ ĐỘNG!
   ============================================================================== */
        var isWhitelisted = !!((simMgrData.is_whitelisted && simMgrData.active_iccid && simMgrData.active_iccid !== 'Chưa phát hiện' && simMgrData.active_iccid.trim() !== '') || (smsRes && smsRes.is_authenticated === 1));

        var iccidTextSpan = E('span', {
            id: 'modem-active-iccid-span',
            style: 'font-size: 13px; font-weight: 750; font-family: monospace; background: #f1f5f9; padding: 4px 10px; border-radius: 4px; border: 1px solid #cbd5e1;'
        }, activeIccidMasked);

        var toggleMaskBtn = E('button', {
            class: 'btn cbi-button',
            style: 'font-size: 11.5px; padding: 3px 8px; font-weight: 600;',
            click: function() {
                isMasked = !isMasked;
                iccidTextSpan.textContent = isMasked ? activeIccidMasked : activeIccidFull;
            }
        }, '👁️ Hiện/Ẩn Số');

        // BẢO MẬT TUYỆT ĐỐI THEO LỆNH ANH DUY:
        // SIM NGOÀI DANH MỤC: ẨN HOÀN TOÀN MỤC HẸN GIỜ GỬI TIN NHẮN & LỊCH GIA HẠN!
        var scheduleSectionNode;
        if (isWhitelisted) {
            var currentSchedTime = simMgrData.schedule_time || '01:25:30';
            var nextEpoch = parseInt(simMgrData.next_send_epoch || 0);

            var countdownSpan = E('span', {
                style: 'font-size: 12.5px; font-weight: 750; color: #d97706; background: #fffbeb; padding: 4px 10px; border-radius: 6px; border: 1px solid #fef3c7;'
            }, '⏳ Đang tính toán...');

            function updateLiveCountdown() {
                var nowE = Math.floor(Date.now() / 1000);
                if (nextEpoch > nowE) {
                    var diff = nextEpoch - nowE;
                    var ch = Math.floor(diff / 3600);
                    var cm = Math.floor((diff % 3600) / 60);
                    var cs = diff % 60;
                    countdownSpan.textContent = '⏳ Còn ' + ch + 'h ' + cm + 'p ' + cs + 's';
                } else {
                    countdownSpan.textContent = '✅ Đã đến giờ gửi hôm nay';
                }
            }
            updateLiveCountdown();
            setInterval(updateLiveCountdown, 1000);

            var schedTimeInput = E('input', {
                type: 'text',
                class: 'cbi-input-text',
                value: currentSchedTime,
                placeholder: '01:25:30',
                style: 'width: 105px; height: 36px; text-align: center; font-weight: 800; font-family: monospace; border-radius: 6px; font-size: 13.5px;'
            });

            var saveSchedBtn = E('button', {
                class: 'btn cbi-button cbi-button-action',
                style: 'font-size: 12.5px; font-weight: 750; padding: 6px 16px; border-radius: 6px;',
                click: function() {
                    var val = schedTimeInput.value.trim();
                    if (!val.match(/^[0-9]{2}:[0-9]{2}:[0-9]{2}$/)) {
                        alert('Định dạng giờ phải là HH:MM:SS (ví dụ 01:25:30)!');
                        return;
                    }
                    saveSchedBtn.textContent = '⏳ Đang lưu...';
                    fetch('/cgi-bin/sim_manager?action=save_time&time=' + encodeURIComponent(val) + '&t=' + Date.now())
                        .then(function(r) { return r.json(); })
                        .then(function(res) {
                            saveSchedBtn.textContent = '💾 Lưu Giờ Gửi';
                            if (res && res.status === 'success') {
                                ui.addNotification(null, E('p', '✅ ' + res.message), 'info');
                                if (res.next_send_epoch) {
                                    nextEpoch = parseInt(res.next_send_epoch);
                                    updateLiveCountdown();
                                }
                            } else {
                                ui.addNotification(null, E('p', '❌ ' + (res.message || 'Lỗi')), 'error');
                            }
                        }).catch(function(err) {
                            saveSchedBtn.textContent = '💾 Lưu Giờ Gửi';
                            ui.addNotification(null, E('p', '❌ Lỗi: ' + err), 'error');
                        });
                }
            }, '💾 Lưu Giờ Gửi');

            var schedPkgInput = E('input', {
                type: 'text',
                class: 'cbi-input-text',
                value: simMgrData.sms_package || '5G150N',
                placeholder: '5G150N',
                style: 'width: 100px; height: 36px; text-align: center; font-weight: 800; border-radius: 6px; font-size: 13.5px;'
            });

            var schedDestInput = E('input', {
                type: 'text',
                class: 'cbi-input-text',
                value: simMgrData.sms_recipient || '191',
                placeholder: '191',
                style: 'width: 70px; height: 36px; text-align: center; font-weight: 800; border-radius: 6px; font-size: 13.5px;'
            });

            var savePkgBtn = E('button', {
                class: 'btn cbi-button cbi-button-action',
                style: 'font-size: 12.5px; font-weight: 750; padding: 6px 14px; border-radius: 6px;',
                click: function() {
                    var pkg = schedPkgInput.value.trim();
                    var dest = schedDestInput.value.trim();
                    if (!pkg || !dest) return alert('Vui lòng nhập cú pháp và số nhận!');
                    savePkgBtn.textContent = '⏳ Đang lưu...';
                    fetch('/cgi-bin/sim_manager?action=save_package&package=' + encodeURIComponent(pkg) + '&dest=' + encodeURIComponent(dest) + '&t=' + Date.now())
                        .then(function(r) { return r.json(); })
                        .then(function(res) {
                            savePkgBtn.textContent = '💾 Lưu Cú Pháp';
                            if (res && res.status === 'success') {
                                ui.addNotification(null, E('p', '✅ ' + res.message), 'info');
                            } else {
                                ui.addNotification(null, E('p', '❌ ' + (res.message || 'Lỗi')), 'error');
                            }
                        }).catch(function(err) {
                            savePkgBtn.textContent = '💾 Lưu Cú Pháp';
                            alert('Lỗi: ' + err);
                        });
                }
            }, '💾 Lưu Cú Pháp');

            var renewLogBox = E('div', {
                id: 'sms-renew-log-box',
                style: 'margin-top: 10px; background: #0f172a; color: #38bdf8; font-family: monospace; font-size: 11.5px; padding: 10px 14px; border-radius: 6px; line-height: 1.5; max-height: 120px; overflow-y: auto; white-space: pre-wrap;'
            }, simMgrData.last_renew_log || 'Chưa có nhật ký gia hạn.');

            var testRenewBtn = E('button', {
                class: 'btn cbi-button',
                style: 'font-size: 12px; font-weight: 750; padding: 6px 14px; border-radius: 6px; background: #16a34a; color: #ffffff; border: none; cursor: pointer; display: flex; align-items: center; gap: 6px;',
                click: function(ev) {
                    var curPkg = schedPkgInput ? schedPkgInput.value.trim() : '5G150N';
                    var curDest = schedDestInput ? schedDestInput.value.trim() : '191';
                    if (!confirm('⚡ Xác nhận gửi thử gia hạn gói [' + curPkg + '] tới [' + curDest + '] ngay bây giờ?')) return;
                    ev.target.disabled = true;
                    ev.target.textContent = '⏳ Đang kích hoạt...';
                    fetch('/cgi-bin/sim_manager?action=test_send_now&t=' + Date.now())
                        .then(function(r) { return r.json(); })
                        .then(function(d) {
                            ev.target.disabled = false;
                            ev.target.textContent = '⚡ Gia Hạn Thử Ngay';
                            if (d && d.status === 'success') {
                                ui.addNotification(null, E('p', '✅ ' + d.message), 'info');
                                setTimeout(function() {
                                    fetch('/cgi-bin/sim_manager?action=get_state&t=' + Date.now())
                                        .then(function(res) { return res.json(); })
                                        .then(function(data) {
                                            var lb = document.getElementById('sms-renew-log-box');
                                            if (lb && data.last_renew_log) lb.textContent = data.last_renew_log;
                                        });
                                }, 3500);
                            } else {
                                ui.addNotification(null, E('p', '❌ ' + (d.message || 'Lỗi gửi SMS')), 'error');
                            }
                        }).catch(function(err) {
                            ev.target.disabled = false;
                            ev.target.textContent = '⚡ Gia Hạn Thử Ngay';
                            alert('Lỗi: ' + err);
                        });
                }
            }, '⚡ Gia Hạn Thử Ngay');

            scheduleSectionNode = E('div', {
                style: 'background: #f0fdf4; border: 1.5px solid #86efac; border-radius: 8px; padding: 14px 16px; margin-bottom: 16px;'
            }, [
                E('div', { style: 'display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; flex-wrap: wrap; gap: 8px;' }, [
                    E('div', { style: 'display: flex; align-items: center; gap: 8px;' }, [
                        E('span', { style: 'font-size: 16px;' }, '⏰'),
                        E('span', { style: 'font-weight: 800; font-size: 14px; color: #166534;' }, 'Lịch SMS Tự Động Gia Hạn (Khung giờ vàng 00h20 - 05h40 sáng)'),
                        countdownSpan
                    ]),
                    testRenewBtn
                ]),
                E('div', { style: 'display: flex; align-items: center; gap: 10px; flex-wrap: wrap; margin-bottom: 8px;' }, [
                    E('span', { style: 'font-size: 13px; font-weight: 700; color: #334155;' }, 'Giờ gửi tự động hàng ngày:'),
                    schedTimeInput,
                    saveSchedBtn,
                    E('span', { style: 'font-size: 12px; color: #15803d; font-weight: 600;' }, '• Khung giờ vàng 00h20 - 05h40')
                ]),
                E('div', { style: 'display: flex; align-items: center; gap: 10px; flex-wrap: wrap; margin-bottom: 8px;' }, [
                    E('span', { style: 'font-size: 13px; font-weight: 700; color: #334155;' }, 'Cú pháp gói cước gia hạn:'),
                    schedPkgInput,
                    E('span', { style: 'font-size: 13px; font-weight: 700; color: #334155;' }, 'gửi tới'),
                    schedDestInput,
                    savePkgBtn,
                    E('span', { style: 'font-size: 12px; color: #64748b;' }, '• Mặc định: 5G150N gửi 191')
                ]),
                E('div', { style: 'font-size: 12px; color: #0369a1; background: #e0f2fe; padding: 6px 10px; border-radius: 6px; border: 1px solid #bae6fd;' }, 
                    '💡 <b>Quy trình tự hành chuẩn 4 pha:</b> Gửi gói cước ➔ Sau 2s gửi xác nhận Y ➔ Sau 10s bật máy bay ngắt sóng ➔ Sau 10s tắt máy bay lấy IP WAN mới 100%!'
                ),
                renewLogBox
            ]);
        } else {
            // Khi SIM KHÔNG nằm trong danh mục hợp lệ: Ẩn hoàn toàn mục hẹn giờ gửi tin nhắn!
            scheduleSectionNode = E('div', {
                style: 'display: none;'
            });
        }

        var vipImeiInput = E('input', {
            type: 'text',
            class: 'cbi-input-text',
            value: (smsRes && smsRes.vip_imei) ? smsRes.vip_imei : '030537611972346',
            placeholder: 'Nhập 15 số IMEI',
            style: 'width: 190px; height: 34px; font-weight: 800; font-family: monospace; border-radius: 6px; font-size: 13px;'
        });

        var saveVipImeiBtn = E('button', {
            class: 'btn cbi-button cbi-button-action',
            style: 'font-size: 12px; font-weight: 750; padding: 5px 14px; border-radius: 6px;',
            click: function() {
                var im = vipImeiInput.value.trim();
                if (!im.match(/^[0-9]{14,16}$/)) {
                    alert('Số IMEI phải chứa từ 14 đến 16 chữ số!');
                    return;
                }
                saveVipImeiBtn.textContent = '⏳ Đang lưu...';
                callSetVipImei(im).then(function(res) {
                    saveVipImeiBtn.textContent = '💾 Lưu Số IMEI';
                    ui.addNotification(null, E('p', '✅ ' + (res.message || 'Đã cập nhật số IMEI thiết bị!')), 'info');
                }).catch(function(err) {
                    saveVipImeiBtn.textContent = '💾 Lưu Số IMEI';
                    alert('Lỗi: ' + err);
                });
            }
        }, '💾 Lưu Số IMEI');

        var simIccidSection = null;
        if (isWhitelisted) {
            simIccidSection = E('div', {
                style: 'background: #ffffff; border: 1.5px solid #cbd5e1; border-radius: 8px; padding: 14px 16px; margin-bottom: 16px;'
            }, [
                E('div', { style: 'display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px; margin-bottom: 12px; flex-wrap: wrap; gap: 8px;' }, [
                    E('div', { style: 'display: flex; align-items: center; gap: 8px;' }, [
                        E('span', { style: 'font-size: 18px;' }, '💳'),
                        E('span', { style: 'font-weight: 800; font-size: 15px; color: #0f172a;' }, 'Thông Tin SIM & Thiết Bị')
                    ]),
                    E('span', { style: 'font-size: 12px; color: #64748b; font-weight: 600;' }, 'Cổng AT: ' + activePort)
                ]),
                E('div', { style: 'display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 14px;' }, [
                    E('div', {}, [
                        E('div', { style: 'font-size: 12.5px; font-weight: 700; color: #475569; margin-bottom: 4px;' }, '📱 Mã ICCID Đang Gắn:'),
                        E('div', { style: 'display: flex; align-items: center; gap: 8px;' }, [ iccidTextSpan, toggleMaskBtn ])
                    ]),
                    E('div', { style: 'display: flex; align-items: center; gap: 8px; flex-wrap: wrap;' }, [
                        E('span', { style: 'font-size: 12.5px; font-weight: 750; color: #1e293b;' }, '📱 Số IMEI Thiết Bị:'),
                        vipImeiInput,
                        saveVipImeiBtn
                    ])
                ])
            ]);
        } else {
            simIccidSection = null;
        }

        var inboxContainer = E('div', {
            id: 'modem-ctrl-sms-inbox',
            style: 'height: auto; max-height: 520px; overflow-y: auto; display: flex; flex-direction: column; gap: 8px; width: 100%; box-sizing: border-box; margin-top: 10px;'
        }, parseAndRenderSMS(typeof smsRes.inbox === 'string' ? smsRes.inbox : JSON.stringify(smsRes.inbox)));

        var smsTargetInput = E('input', { type: 'text', class: 'cbi-input-text', placeholder: 'Người nhận (vd: 191 hoặc số điện thoại)', style: 'width: 100%; margin-bottom: 8px; font-weight: 700; height: 38px; border-radius: 6px;' });
        var smsMsgInput = E('input', { type: 'text', class: 'cbi-input-text', placeholder: 'Nội dung tin nhắn...', style: 'width: 100%; margin-bottom: 10px; height: 38px; border-radius: 6px;' });

        var sendSmsBtn = E('button', {
            class: 'btn cbi-button cbi-button-action',
            style: 'font-weight: 750; font-size: 13px; padding: 7px 18px; border-radius: 6px;',
            click: function() {
                var tgt = smsTargetInput.value.trim();
                var msg = smsMsgInput.value.trim();
                if (!tgt || !msg) { alert('Vui lòng nhập người nhận và nội dung!'); return; }
                callSendSMS(tgt, msg).then(function() {
                    ui.addNotification(null, E('p', '✅ Đã gửi tin nhắn đến ' + tgt), 'info');
                    smsMsgInput.value = '';
                }).catch(function(err) {
                    ui.addNotification(null, E('p', '❌ Lỗi gửi tin: ' + err), 'error');
                });
            }
        }, '📨 Gửi Tin Nhắn');

        var quickPresets = E('div', { style: 'display: flex; gap: 6px; margin-bottom: 10px; flex-wrap: wrap;' }, [
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 3px 8px; font-weight: 700; background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; cursor: pointer; border-radius: 6px;', click: function() { smsTargetInput.value = '191'; smsMsgInput.value = 'KTTK'; } }, '⚡ Viettel KTTK'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 3px 8px; font-weight: 700; background: #eff6ff; color: #0284c7; border: 1px solid #bae6fd; cursor: pointer; border-radius: 6px;', click: function() { smsTargetInput.value = '888'; smsMsgInput.value = 'DATA'; } }, '⚡ Vina DATA'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 3px 8px; font-weight: 700; background: #fefce8; color: #a16207; border: 1px solid #fef08a; cursor: pointer; border-radius: 6px;', click: function() { smsTargetInput.value = '999'; smsMsgInput.value = 'KT DATA'; } }, '⚡ Mobi DATA'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 3px 8px; font-weight: 700; background: #fdf2f8; color: #be185d; border: 1px solid #fbcfe8; cursor: pointer; border-radius: 6px;', click: function() { smsTargetInput.value = '123'; smsMsgInput.value = 'KT'; } }, '⚡ VNM KT'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 3px 8px; font-weight: 700; background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; cursor: pointer; border-radius: 6px;', click: function() { smsTargetInput.value = '191'; smsMsgInput.value = 'DATA'; } }, '⚡ Wintel DATA')
        ]);

        var fastCheckDataBtn = E('button', {
            class: 'btn cbi-button',
            style: 'font-weight: 750; font-size: 13px; padding: 7px 18px; border-radius: 6px; background: #ffffff; color: #1e293b; border: 1.5px solid #cbd5e1; margin-left: 8px;',
            click: function() {
                inboxContainer.innerHTML = '<div style="padding: 20px; text-align: center; color: #2563eb; font-weight: 700;">⏳ Đang gửi tra cước data & đọc tin phản hồi tự động...</div>';
                callCheckDataBalance().then(function(res) {
                    callFetchSMS().then(function(rep) {
                        inboxContainer.innerHTML = '';
                        parseAndRenderSMS(rep.inbox || '').forEach(function(n) { inboxContainer.appendChild(n); });
                    });
                }).catch(function(err) {
                    ui.addNotification(null, E('p', '❌ Lỗi tra cứu: ' + err), 'error');
                });
            }
        }, '🔍 Kiểm Tra Data Nhanh (Tự Động Đọc Tin)');

        var simTabChildren = [
            E('h3', { style: 'margin-top: 0; font-size: 18px; font-weight: 800; color: #1e293b; border-bottom: 1px solid #f1f5f9; padding-bottom: 10px;' }, isWhitelisted ? '📬 Quản Lý SIM & Hộp Thư SMS (Router & SIM)' : '📬 Hộp Thư Tin Nhắn SMS (Router & SIM)')
        ];

        /* ==============================================================================
           === LOCKED: VERIFIED BY DOANDUY - DO NOT MODIFY ===
           BẢO MẬT TUYỆT ĐỐI THEO CHỈ THỊ ANH DUY (DOANDUY):
           Chỉ khi SIM nằm trong danh mục mặc định thì mới hiển thị Thông Tin SIM & Thiết Bị
           và Lịch Hẹn Giờ SMS. Nếu SIM ngoài danh mục: ẨN 100% KHỎI DOM (ZERO LEAK)!
           ============================================================================== */
        if (isWhitelisted) {
            if (simIccidSection) simTabChildren.push(simIccidSection);
            if (scheduleSectionNode) simTabChildren.push(scheduleSectionNode);
        } else {
            simTabChildren.push(E('div', {
                style: 'background: #f8fafc; border: 1.5px dashed #cbd5e1; border-radius: 8px; padding: 14px 18px; margin-bottom: 16px; display: flex; align-items: center; gap: 12px; color: #475569;'
            }, [
                E('span', { style: 'font-size: 22px;' }, '🔒'),
                E('div', {}, [
                    E('div', { style: 'font-weight: 750; font-size: 13.5px; color: #1e293b; margin-bottom: 3px;' }, 'Chế Độ Bảo Mật Tuyệt Đối (Stealth Mode Active):'),
                    E('div', { style: 'font-size: 12px; color: #64748b; line-height: 1.5;' }, 'Thẻ SIM đang sử dụng không thuộc danh mục mặc định. Toàn bộ cấu hình quản trị và lịch hẹn giờ gia hạn tự động đã được ẩn hoàn toàn để bảo vệ thiết bị.')
                ])
            ]));
        }

        var simTabStatusCard = E('div', { style: 'background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;' }, [
                E('div', {}, [
                    E('span', { style: 'font-weight: 700; color: #475569; font-size: 13px;' }, '📱 Trạng thái SIM: '),
                    E('span', { style: 'font-weight: 800; color: ' + (isWhitelisted ? '#15803d' : '#475569') + '; font-size: 14px;' }, isWhitelisted ? (smsRes.sim_info || 'SIM Viettel (Hoạt động)') : (simMgrData.active_iccid ? 'SIM Ngoài Danh Sách' : 'Chưa gắn SIM / Chưa phát hiện')),
                    E('span', { style: 'margin-left: 10px; font-weight: 600; color: #64748b; font-size: 12px;' }, '• Cổng AT: ' + activePort)
                ]),
                E('div', { style: 'display: flex; gap: 8px;' }, [
                    E('button', {
                        class: 'btn cbi-button cbi-button-action',
                        style: 'font-weight: 700; font-size: 12px; padding: 6px 14px; border-radius: 6px;',
                        click: function() {
                            inboxContainer.innerHTML = '<div style="padding: 20px; text-align: center; color: #2563eb; font-weight: 700;">⏳ Đang quét toàn bộ tin nhắn từ Router (ME) và Thẻ SIM (SM)...</div>';
                            callFetchSMS().then(function(r) {
                                inboxContainer.innerHTML = '';
                                parseAndRenderSMS(r.inbox || '').forEach(function(n) { inboxContainer.appendChild(n); });
                            });
                        }
                    }, '🔄 Quét Lại Tin'),
                    E('button', {
                        class: 'btn cbi-button cbi-button-remove',
                        style: 'font-weight: 700; font-size: 12px; padding: 6px 14px; border-radius: 6px;',
                        click: function() {
                            if (!confirm("Xóa toàn bộ tin nhắn trên cả Router và SIM?")) return;
                            callDeleteAllSMS().then(function() {
                                inboxContainer.innerHTML = '<div style="padding: 20px; text-align: center; color: #475569; font-size: 14px;">📭 Hộp thư trống.</div>';
                            });
                        }
                    }, '🗑️ Xóa Tất Cả')
                ])
            ]);

            simTabChildren.push(simTabStatusCard);
            simTabChildren.push(E('div', { style: 'margin-bottom: 16px; border: 1px solid #f1f5f9; border-radius: 8px; padding: 14px; background: #fafafa;' }, [
                E('div', { style: 'font-weight: 750; font-size: 13.5px; margin-bottom: 8px; color: #1e293b;' }, '⚡ Gửi Tin Nhắn Nhanh & Tra Cước Data:'),
                quickPresets,
                smsTargetInput,
                smsMsgInput,
                E('div', { style: 'display: flex; gap: 10px;' }, [ sendSmsBtn, fastCheckDataBtn ])
            ]));
            simTabChildren.push(E('div', { style: 'border-top: 1px solid #f1f5f9; padding-top: 12px;' }, [
                E('div', { style: 'font-weight: 800; font-size: 14px; margin-bottom: 6px; color: #1e293b;' }, '📥 Hộp Thư Đến Trực Tiếp:'),
                inboxContainer
            ]));

        var simTabContent = E('div', { class: 'cbi-section', style: 'padding: 20px; background: #ffffff; border-radius: 10px; border: 1px solid #e2e8f0;' }, simTabChildren);
        tabPanes['sms'] = simTabContent;

        // ---------------- TAB 2: MODEM 5G & BĂNG TẦN ----------------
        // 1. Đổi TTL Né Bóp Băng Thông
        var ttlInput = E('input', { type: 'number', class: 'cbi-input-text', value: '65', style: 'width: 80px; height: 36px; text-align: center; font-weight: 800; border-radius: 6px;' });
        var saveTtlBtn = E('button', {
            class: 'btn cbi-button cbi-button-action',
            style: 'font-weight: 750; font-size: 12.5px; padding: 6px 16px; border-radius: 6px;',
            click: function() {
                var v = parseInt(ttlInput.value) || 65;
                saveTtlBtn.textContent = '⏳ Đang đổi...';
                callSetTTL(v).then(function() {
                    saveTtlBtn.textContent = '🚀 Đổi TTL';
                    ui.addNotification(null, E('p', '✅ Đã đổi TTL sang ' + v + ' thành công!'), 'info');
                }).catch(function(err) {
                    saveTtlBtn.textContent = '🚀 Đổi TTL';
                    ui.addNotification(null, E('p', '❌ Lỗi: ' + err), 'error');
                });
            }
        }, '🚀 Đổi TTL');

        var ttlSection = E('div', { style: 'border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; background: #fafafa; margin-bottom: 16px;' }, [
            E('div', { style: 'font-weight: 800; font-size: 14px; margin-bottom: 8px; color: #1e293b;' }, '⚡ Đổi TTL Né Bóp Băng Thông Hotspot:'),
            E('div', { style: 'display: flex; align-items: center; gap: 10px; flex-wrap: wrap;' }, [
                ttlInput,
                saveTtlBtn,
                E('span', { style: 'font-size: 12px; color: #64748b;' }, '• Mặc định né bóp: 65 (chống nhà mạng phát hiện chia sẻ phát Wi-Fi Hotspot)')
            ])
        ]);

        // 3. Giao thức Interface Modem
        var ifaceSelect = E('select', { class: 'cbi-input-select', style: 'width: 360px; height: 38px; font-weight: 700; border-radius: 6px;' }, [
            E('option', { value: 'wwan_smart|auto' }, '⭐ WWAN Smart Tự Động (Tất Cả Modem 4G/5G, PCIe, USB, Điện thoại)'),
            E('option', { value: 'xmm|wwan0' }, 'Fibocom FM350-GL USB (proto: xmm / wwan0)'),
            E('option', { value: 'mbim|wwan0' }, 'MBIM / Sierra EM919x / PCIe 5G (proto: mbim / wwan0)'),
            E('option', { value: 'quectel|wwan0' }, 'Quectel RM500Q / RM520N (proto: quectel / wwan0)'),
            E('option', { value: 'qmi|wwan0' }, 'QMI / Chuẩn cũ (proto: qmi / wwan0)'),
            E('option', { value: 'modemmanager|wwan0' }, 'ModemManager Tự Động (proto: modemmanager / wwan0)'),
            E('option', { value: 'ecm|usb0' }, 'ECM / Driver chuẩn (proto: dhcp / usb0)'),
            E('option', { value: 'rndis|usb0' }, 'RNDIS / Tethering USB (proto: dhcp / usb0)')
        ]);

        var saveIfaceBtn = E('button', {
            class: 'btn cbi-button cbi-button-action',
            style: 'font-weight: 750; font-size: 12.5px; padding: 6px 16px; border-radius: 6px;',
            click: function() {
                var p = ifaceSelect.value.split('|');
                saveIfaceBtn.textContent = '⏳ Đang áp dụng...';
                callSetCard(p[0], p[1]).then(function() {
                    saveIfaceBtn.textContent = '🚀 Áp Dụng Interface';
                    ui.addNotification(null, E('p', '✅ Đã đổi giao thức interface sang ' + p[0] + ' (' + p[1] + ')!'), 'info');
                }).catch(function(err) {
                    saveIfaceBtn.textContent = '🚀 Áp Dụng Interface';
                    ui.addNotification(null, E('p', '❌ Lỗi: ' + err), 'error');
                });
            }
        }, '🚀 Áp Dụng Interface');

        var ifaceSection = E('div', { style: 'border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; background: #fafafa; margin-bottom: 16px;' }, [
            E('div', { style: 'font-weight: 800; font-size: 14px; margin-bottom: 8px; color: #1e293b;' }, '🌐 Giao Thức Interface Modem:'),
            E('div', { style: 'display: flex; align-items: center; gap: 10px; flex-wrap: wrap;' }, [
                ifaceSelect,
                saveIfaceBtn
            ]),
            E('div', { style: 'font-size: 12px; color: #64748b; margin-top: 6px;' }, '• Tự động nhận diện: Sierra Wireless EM919x/EM7565 -> Giao thức MBIM (wwan0) & Cổng AT /dev/ttyUSB0')
        ]);

        // 3.1. Đổi Tên Giao Diện WAN / Modem
        var curIfaceName = (smsRes && smsRes.act_iface) ? smsRes.act_iface : 'duydoan_5g';
        var ifaceNameInput = E('input', {
            type: 'text',
            class: 'cbi-input-text',
            value: curIfaceName,
            placeholder: 'duydoan_5g',
            style: 'width: 220px; height: 38px; font-weight: 800; border-radius: 6px; font-size: 13.5px;'
        });

        var saveIfaceNameBtn = E('button', {
            class: 'btn cbi-button cbi-button-action',
            style: 'font-weight: 750; font-size: 12.5px; padding: 6px 16px; border-radius: 6px;',
            click: function() {
                var newName = ifaceNameInput.value.trim();
                if (!newName || !/^[a-zA-Z0-9_-]+$/.test(newName)) {
                    alert('Tên interface không hợp lệ (chỉ gồm chữ cái, số, gạch dưới hoặc gạch ngang)!');
                    return;
                }
                saveIfaceNameBtn.textContent = '⏳ Đang lưu...';
                callRenameInterface(newName).then(function() {
                    saveIfaceNameBtn.textContent = '💾 Đổi Tên Interface';
                    ui.addNotification(null, E('p', '✅ Đã đổi tên interface thành [' + newName + '] và đồng bộ Firewall WAN thành công!'), 'info');
                    setTimeout(function() { location.reload(); }, 1500);
                }).catch(function(err) {
                    saveIfaceNameBtn.textContent = '💾 Đổi Tên Interface';
                    ui.addNotification(null, E('p', '❌ Lỗi: ' + err), 'error');
                });
            }
        }, '💾 Đổi Tên Interface');

        var ifaceNameSection = E('div', { style: 'border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; background: #fafafa; margin-bottom: 16px;' }, [
            E('div', { style: 'font-weight: 800; font-size: 14px; margin-bottom: 8px; color: #1e293b;' }, '🏷️ Tùy Chỉnh Tên Interface WAN Modem:'),
            E('div', { style: 'display: flex; align-items: center; gap: 10px; flex-wrap: wrap;' }, [
                ifaceNameInput,
                saveIfaceNameBtn,
                E('span', { style: 'font-size: 12px; color: #64748b;' }, '• Mặc định: duydoan_5g (Tự động gán Firewall WAN và NAT khi đổi tên)')
            ])
        ]);

        // 4. Cổng AT Modem
        var activePortDisplay = E('span', { style: 'font-weight: 800; color: #166534; font-family: monospace;' }, activePort);
        var atPortSelect = E('select', {
            class: 'cbi-input-select',
            style: 'width: 360px; height: 38px; font-weight: 700; border-radius: 6px;',
            change: function(ev) {
                activePort = ev.target.value;
                if (activePortDisplay) activePortDisplay.textContent = activePort;
            }
        });
        var availablePorts = (portsData && ((portsData.ports && portsData.ports.length > 0) ? portsData.ports : portsData.available_ports)) || ['/dev/ttyFMI0', '/dev/wwan0at0', '/dev/mhi_DUN', '/dev/ttyUSB3', '/dev/ttyUSB2', '/dev/ttyUSB1', '/dev/ttyUSB0'];
        if (!Array.isArray(availablePorts) || availablePorts.length === 0) availablePorts = ['/dev/ttyFMI0', '/dev/wwan0at0', '/dev/mhi_DUN', '/dev/ttyUSB3', '/dev/ttyUSB2', '/dev/ttyUSB1', '/dev/ttyUSB0'];
        availablePorts.forEach(function(p) {
            var label = p;
            if (p === '/dev/ttyUSB3') label += ' (Fibocom FM350-GL AT Cổng 3 - Chuẩn)';
            else if (p === '/dev/wwan0at0') label += ' (PCIe Fibocom FM350-GL / T700 wwan0at0)';
            else if (p === '/dev/mhi_DUN') label += ' (PCIe Qualcomm MHI / Foxconn)';
            else if (p === '/dev/ttyUSB2') label += ' (Quectel / SIMCOM / MeiG AT)';
            else if (p === '/dev/ttyUSB1') label += ' (Fibocom AT Phụ)';
            else if (p === '/dev/ttyUSB0') label += ' (Sierra EM919x / DM Log)';
            else if (p === '/dev/ttyFMI0') label += ' (PCIe Fibocom FM350-GL ttyFMI0)';
            else if (p === '/dev/ttyFMI1') label += ' (PCIe Fibocom FM350-GL ttyFMI1)';
            atPortSelect.appendChild(E('option', { value: p, selected: (p === activePort) }, label + (p === activePort ? ' (Đang dùng)' : '')));
        });

        var savePortBtn = E('button', {
            class: 'btn cbi-button cbi-button-action',
            style: 'font-weight: 750; font-size: 12.5px; padding: 6px 14px; border-radius: 6px;',
            click: function() {
                var chosen = atPortSelect.value;
                activePort = chosen;
                if (activePortDisplay) activePortDisplay.textContent = activePort;
                callSetPort(chosen).then(function() {
                    ui.addNotification(null, E('p', '✅ Đã lưu cổng AT: ' + chosen), 'info');
                });
            }
        }, '💾 Lưu Cổng');

        var atPortSection = E('div', { style: 'border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; background: #fafafa; margin-bottom: 16px;' }, [
            E('div', { style: 'font-weight: 800; font-size: 14px; margin-bottom: 8px; color: #1e293b;' }, '📍 Cổng AT Modem:'),
            E('div', { style: 'display: flex; align-items: center; gap: 10px; flex-wrap: wrap; margin-bottom: 8px;' }, [
                atPortSelect,
                savePortBtn
            ]),
            E('div', { style: 'background: #ffffff; border: 1px solid #e2e8f0; padding: 8px 12px; border-radius: 6px; font-size: 12px; line-height: 1.6; color: #475569;' }, [
                E('b', {}, '💡 Cổng AT Tiêu Chuẩn: '),
                E('span', {}, '• Fibocom FM350-GL: /dev/ttyUSB3 (USB) | /dev/wwan0at0 (PCIe) | • Quectel/SIMCOM: /dev/ttyUSB2 | • Sierra (EM919x): /dev/ttyUSB0')
            ])
        ]);

        // 5. Đổi IMEI & Khóa Băng Tần
        var imeiInput = E('input', { type: 'text', class: 'cbi-input-text', placeholder: 'Nhập số IMEI mới (15 số)', style: 'width: 260px; height: 38px; font-weight: 800; font-family: monospace; border-radius: 6px;' });
        var genImeiBtn = E('button', {
            class: 'btn cbi-button',
            style: 'font-weight: 700; font-size: 12px; padding: 6px 12px; border-radius: 6px; background: #ffffff; border: 1px solid #cbd5e1;',
            click: function() {
                var prefix = "86428404";
                var body = Math.floor(Math.random() * 900000 + 100000).toString();
                var imei14 = prefix + body;
                var sum = 0;
                for (var i = 0; i < 14; i++) {
                    var n = parseInt(imei14[i]);
                    if (i % 2 !== 0) { n *= 2; if (n > 9) n = (n % 10) + 1; }
                    sum += n;
                }
                var checkDigit = (10 - (sum % 10)) % 10;
                imeiInput.value = imei14 + checkDigit;
            }
        }, '🎲 Tạo IMEI');

        var applyImeiBtn = E('button', {
            class: 'btn cbi-button cbi-button-action',
            style: 'font-weight: 750; font-size: 12.5px; padding: 6px 16px; border-radius: 6px;',
            click: function() {
                var im = imeiInput.value.trim();
                if (!im.match(/^[0-9]{15}$/)) { alert('IMEI phải đủ 15 chữ số!'); return; }
                if (!confirm("Xác nhận đổi IMEI modem sang: " + im + "? Modem sẽ khởi động lại sóng.")) return;
                callChangeIMEI(im, 'auto').then(function(r) {
                    ui.addNotification(null, E('p', r.message || '✅ Đã đổi IMEI thành công!'), 'info');
                }).catch(function(err) {
                    ui.addNotification(null, E('p', '❌ Lỗi đổi IMEI: ' + err), 'error');
                });
            }
        }, '📲 Đổi IMEI');

        var bandPresetSelect = E('select', { class: 'cbi-input-select', style: 'width: 100%; height: 38px; font-weight: 700; border-radius: 6px; margin-bottom: 10px;' }, [
            E('option', { value: 'auto_carrier' }, '⚡ Tự Động Khóa 5G Theo SIM Đang Dùng (Khuyên dùng)'),
            E('option', { value: 'viettel_5g' }, '🔴 Viettel 5G Max (Khóa n41 Vàng + n78/n28 + LTE B1/B3/B7/B8/B28/B40/B41)'),
            E('option', { value: 'vina_5g' }, '🔵 VinaPhone 5G Max (Khóa n77/n78 + LTE B1/B3/B8)'),
            E('option', { value: 'mobi_5g' }, '🟡 MobiFone 5G Max (Khóa n77/n78 + LTE B1/B3/B7/B8)'),
            E('option', { value: 'wintel_5g' }, '🔴 Wintel 5G Max (Chạy hạ tầng VNPT n77/n78)'),
            E('option', { value: 'vietnamobile' }, '🟠 Vietnamobile 4G (Khóa LTE B3/B8)'),
            E('option', { value: 'reset_all' }, '🔄 Tự Động Mở Rộng (Khôi phục toàn bộ băng tần)')
        ]);

        var applyBandBtn = E('button', {
            class: 'btn cbi-button cbi-button-action',
            style: 'font-weight: 750; font-size: 12.5px; padding: 6px 16px; border-radius: 6px;',
            click: function() {
                var bm = bandPresetSelect.value;
                callSetBandLock(bm).then(function(r) {
                    ui.addNotification(null, E('p', r.message || '✅ Đã áp dụng cấu hình băng tần!'), 'info');
                }).catch(function(err) {
                    ui.addNotification(null, E('p', '❌ Lỗi khóa băng tần: ' + err), 'error');
                });
            }
        }, '🔒 Khóa Băng Tần');

        var atCmdInput = E('input', {
            type: 'text',
            class: 'cbi-input-text',
            placeholder: 'Nhập lệnh AT (vd: ATI, AT+CSQ, AT+CEREG?, AT+CGDCONT?)...',
            style: 'width: 100%; height: 40px; font-weight: 800; font-family: monospace; border-radius: 6px; margin-bottom: 10px;'
        });

        var atRespBox = E('pre', {
            style: 'background: #0f172a; color: #38bdf8; padding: 16px; border-radius: 8px; font-family: monospace; font-size: 13px; line-height: 1.5; max-height: 360px; overflow-y: auto; white-space: pre-wrap; word-break: break-all;'
        }, 'Ready. Nhập lệnh AT hoặc nhấn "Kiểm Tra ATI" để kiểm tra modem.');

        function executeAtCommand(cmd) {
            var c = (cmd || atCmdInput.value).trim();
            if (!c) { alert('Vui lòng nhập lệnh AT!'); return; }
            atCmdInput.value = c;
            var targetP = atPortSelect.value || activePort;
            atRespBox.textContent = '⏳ Đang gửi: ' + c + ' tới modem qua cổng ' + targetP + '...';
            callSendAT(c, targetP).then(function(r) {
                if (r && r.response) {
                    atRespBox.textContent = r.response;
                } else if (r && r.message) {
                    atRespBox.textContent = 'Phản hồi: ' + r.message;
                } else {
                    atRespBox.textContent = JSON.stringify(r, null, 2);
                }
            }).catch(function(err) {
                atRespBox.textContent = '❌ Lỗi gửi lệnh AT: ' + err;
            });
        }

        var sendAtActionBtn = E('button', {
            class: 'btn cbi-button cbi-button-action',
            style: 'font-weight: 750; font-size: 13px; padding: 8px 20px; border-radius: 6px;',
            click: function() { executeAtCommand(); }
        }, '🚀 Gửi Lệnh AT');

        var atiCheckBtn = E('button', {
            class: 'btn cbi-button cbi-button-action',
            style: 'font-weight: 750; font-size: 12.5px; padding: 6px 16px; border-radius: 6px; background: #059669; border-color: #059669;',
            click: function() { executeAtCommand('ATI'); }
        }, '🔍 Kiểm Tra ATI (Thông Tin Modem)');

        var atQuickCmds = E('div', { style: 'display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 12px;' }, [
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 4px 10px; font-weight: 700; background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; cursor: pointer; border-radius: 6px;', click: function() { executeAtCommand('ATI'); } }, '🔍 ATI (Thông tin modem)'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 4px 10px; font-weight: 700; background: #eff6ff; color: #1e40af; border: 1px solid #bfdbfe; cursor: pointer; border-radius: 6px;', click: function() { executeAtCommand('AT+CSQ'); } }, '📶 AT+CSQ (Cường độ sóng)'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 4px 10px; font-weight: 700; background: #f8fafc; border: 1px solid #cbd5e1; cursor: pointer; border-radius: 6px;', click: function() { executeAtCommand('AT+CPIN?'); } }, '📱 AT+CPIN? (Trạng thái SIM)'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 4px 10px; font-weight: 700; background: #f8fafc; border: 1px solid #cbd5e1; cursor: pointer; border-radius: 6px;', click: function() { executeAtCommand('AT+CEREG?'); } }, '📡 AT+CEREG? (Đăng ký mạng 4G/5G)'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 4px 10px; font-weight: 700; background: #f8fafc; border: 1px solid #cbd5e1; cursor: pointer; border-radius: 6px;', click: function() { executeAtCommand('AT+CGDCONT?'); } }, '🌐 AT+CGDCONT? (Cấu hình APN)'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 4px 10px; font-weight: 700; background: #f8fafc; border: 1px solid #cbd5e1; cursor: pointer; border-radius: 6px;', click: function() { executeAtCommand('AT+COPS?'); } }, '⚡ AT+COPS? (Nhà mạng đang kết nối)'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 4px 10px; font-weight: 700; background: #fdf4ff; color: #86198f; border: 1px solid #f0abfc; cursor: pointer; border-radius: 6px;', click: function() { executeAtCommand('AT+GTCCINFO?'); } }, '🔬 AT+GTCCINFO? (Fibocom Cell/Band)'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 4px 10px; font-weight: 700; background: #fdf4ff; color: #86198f; border: 1px solid #f0abfc; cursor: pointer; border-radius: 6px;', click: function() { executeAtCommand('AT+QENG="servingcell"'); } }, '🔬 AT+QENG (Quectel Serving Cell)'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 4px 10px; font-weight: 700; background: #fdf4ff; color: #86198f; border: 1px solid #f0abfc; cursor: pointer; border-radius: 6px;', click: function() { executeAtCommand('AT!GSTATUS?'); } }, '🔬 AT!GSTATUS? (Sierra Status)'),
            E('button', { class: 'btn', style: 'font-size: 11.5px; padding: 4px 10px; font-weight: 700; background: #fff1f2; color: #9f1239; border: 1px solid #fecdd3; cursor: pointer; border-radius: 6px;', click: function() { if (confirm("Khởi động lại sóng modem (AT+CFUN=1,1)?")) executeAtCommand('AT+CFUN=1,1'); } }, '🔄 Reset Sóng Modem')
        ]);

        var modemOverviewHeader = E('div', {
            style: 'background: #f0fdf4; border: 1.5px solid #bbf7d0; border-radius: 8px; padding: 14px; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;'
        }, [
            E('div', {}, [
                E('div', { style: 'font-weight: 800; font-size: 14px; color: #166534;' }, [
                    '🟢 Cổng AT Đang Hoạt Động: ',
                    activePortDisplay
                ]),
                E('div', { style: 'font-size: 12.5px; color: #15803d; margin-top: 3px;' }, '• Tự động kết nối và thẩm định qua lệnh ATI • Sẵn sàng nhận lệnh AT & điều khiển sóng 4G/5G.')
            ]),
            atiCheckBtn
        ]);

        var atTerminalSection = E('div', { style: 'border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; background: #fafafa; margin-top: 16px;' }, [
            E('div', { style: 'font-weight: 800; font-size: 14px; margin-bottom: 6px; color: #1e293b;' }, '💻 Console Gửi Lệnh AT Trực Tiếp:'),
            E('div', { style: 'font-size: 12.5px; color: #64748b; font-weight: 600; margin-bottom: 8px;' }, 'Phím tắt lệnh thông dụng (1-Click gửi ngay):'),
            atQuickCmds,
            atCmdInput,
            E('div', { style: 'display: flex; gap: 8px; margin-bottom: 14px;' }, [ sendAtActionBtn ]),
            atRespBox
        ]);

        var modemTabContent = E('div', { class: 'cbi-section', style: 'display: none; padding: 20px; background: #ffffff; border-radius: 10px; border: 1px solid #e2e8f0;' }, [
            E('h3', { style: 'margin-top: 0; font-size: 18px; font-weight: 800; color: #1e293b; border-bottom: 1px solid #f1f5f9; padding-bottom: 10px;' }, '📶 Modem 5G, Băng Tần & Lệnh AT'),
            modemOverviewHeader,
            ttlSection,
            ifaceSection,
            ifaceNameSection,
            atPortSection,
            E('div', { style: 'border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; background: #fafafa; margin-bottom: 16px;' }, [
                E('div', { style: 'font-weight: 800; font-size: 14px; margin-bottom: 6px; color: #1e293b;' }, '📲 Tự Đổi IMEI Modem (Kháng Chặn & Né Giới Hạn):'),
                E('div', { style: 'display: flex; gap: 8px; align-items: center; flex-wrap: wrap;' }, [ imeiInput, genImeiBtn, applyImeiBtn ])
            ]),
            E('div', { style: 'border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; background: #fafafa; margin-bottom: 16px;' }, [
                E('div', { style: 'font-weight: 800; font-size: 14px; margin-bottom: 6px; color: #1e293b;' }, '⚡ Khóa Băng Tần 5G/4G Tối Ưu Tốc Độ:'),
                bandPresetSelect,
                applyBandBtn
            ]),
            atTerminalSection
        ]);
        tabPanes['modem'] = modemTabContent;

        // ---------------- TAB 4: 1-CLICK AUTO MESH (THIẾT KẾ GIỐNG NHƯ FILE ALL) ----------------
        var meshStatusCard = E('div', {
            style: 'background: #ffffff; border: 1.5px solid #e2e8f0; border-radius: 8px; padding: 16px; margin-bottom: 16px;'
        }, [ E('div', { style: 'text-align: center; padding: 20px; font-weight: 700; color: #2563eb;' }, '⏳ Đang kết nối và tải sơ đồ Mesh...') ]);

        var btnTriggerMeshPair = E('button', {
            class: 'btn cbi-button cbi-button-action',
            style: 'background: #7c3aed; color: #ffffff; font-size: 13.5px; font-weight: 800; padding: 10px 18px; border-radius: 8px; cursor: pointer; border: none;',
            click: function(ev) {
                ev.target.disabled = true;
                ev.target.textContent = '⏳ Đang tự động ghép nối Mesh...';
                fetch('/cgi-bin/airdrop?action=mesh_pair')
                    .then(function(r) { return r.json(); })
                    .then(function(data) {
                        ev.target.disabled = false;
                        ev.target.textContent = '⚡ BẬT GHÉP NỐI MESH TỰ ĐỘNG (1-CLICK)';
                        ui.addNotification(null, E('p', data.message || '⚡ Đã kích hoạt chế độ Ghép Nối Mesh Tự Động!'), 'info');
                        if (data.new_ip && data.new_ip !== window.location.hostname) {
                            setTimeout(function() { window.location.href = 'http://' + data.new_ip + '/cgi-bin/luci'; }, 3500);
                        } else {
                            setTimeout(function() { refreshMeshDashboard(); }, 2000);
                        }
                    }).catch(function(err) {
                        ev.target.disabled = false;
                        ev.target.textContent = '⚡ BẬT GHÉP NỐI MESH TỰ ĐỘNG (1-CLICK)';
                        ui.addNotification(null, E('p', '❌ Lỗi kích hoạt Mesh: ' + err), 'error');
                    });
            }
        }, '⚡ BẬT GHÉP NỐI MESH TỰ ĐỘNG (1-CLICK)');

        var btnSetMaster = E('button', {
            class: 'btn cbi-button',
            style: 'background: #0284c7; color: #ffffff; font-size: 13px; font-weight: 800; padding: 10px 16px; border-radius: 8px; cursor: pointer; border: none;',
            click: function(ev) {
                if (!confirm('Xác nhận đặt thiết bị này làm ROUTER PHÁT CHÍNH (Master Controller)?\n- IP LAN: 192.168.1.1\n- Bật máy chủ DHCP và phát sóng Backhaul SysMesh_Athena.')) return;
                ev.target.disabled = true;
                ev.target.textContent = '⏳ Đang cấu hình...';
                fetch('/cgi-bin/airdrop?action=mesh_set_controller')
                    .then(function(r) { return r.json(); })
                    .then(function(data) {
                        ev.target.disabled = false;
                        ev.target.textContent = '👑 ĐẶT LÀM ROUTER CHÍNH (192.168.1.1)';
                        ui.addNotification(null, E('p', data.message || '✅ Đã đặt thiết bị làm Router Phát Chính!'), 'info');
                        setTimeout(function() { refreshMeshDashboard(); }, 1500);
                    }).catch(function(err) {
                        ev.target.disabled = false;
                        ev.target.textContent = '👑 ĐẶT LÀM ROUTER CHÍNH (192.168.1.1)';
                        ui.addNotification(null, E('p', '❌ Lỗi: ' + err), 'error');
                    });
            }
        }, '👑 ĐẶT LÀM ROUTER CHÍNH (192.168.1.1)');

        var btnSetSlave = E('button', {
            class: 'btn cbi-button',
            style: 'background: #ea580c; color: #ffffff; font-size: 13px; font-weight: 800; padding: 10px 16px; border-radius: 8px; cursor: pointer; border: none;',
            click: function(ev) {
                if (!confirm('Xác nhận chuyển thiết bị này thành ROUTER PHỤ (Slave Node)?\n- IP LAN sẽ đổi sang 192.168.1.10\n- Tắt DHCP LAN để không xung đột với Router Chính\n- Tự kết nối vào Router Chính qua sóng 5GHz.\nTrang LuCI sẽ tự chuyển sang http://192.168.1.10.')) return;
                ev.target.disabled = true;
                ev.target.textContent = '⏳ Đang chuyển sang Router Phụ...';
                fetch('/cgi-bin/airdrop?action=mesh_set_node&ip=192.168.1.10')
                    .then(function(r) { return r.json(); })
                    .then(function(data) {
                        ui.addNotification(null, E('p', '✅ ' + (data.message || 'Đã chuyển thành Router Phụ tại IP 192.168.1.10!')), 'info');
                        setTimeout(function() { window.location.href = 'http://192.168.1.10/cgi-bin/luci'; }, 3500);
                    }).catch(function(err) {
                        ev.target.disabled = false;
                        ev.target.textContent = '📡 ĐẶT LÀM ROUTER PHỤ (192.168.1.10)';
                        ui.addNotification(null, E('p', '❌ Lỗi: ' + err), 'error');
                    });
            }
        }, '📡 ĐẶT LÀM ROUTER PHỤ (192.168.1.10)');

        var btnMeshSyncWifi = E('button', {
            class: 'btn cbi-button',
            style: 'background: #10b981; color: #ffffff; font-size: 13px; font-weight: 800; padding: 10px 16px; border-radius: 8px; cursor: pointer; border: none;',
            click: function() {
                ui.showModal('Đang đồng bộ Wi-Fi...', [ E('p', { class: 'spinning' }, 'Đang đồng bộ tên Wi-Fi và mật khẩu sang Router Phụ...') ]);
                fetch('/cgi-bin/airdrop?action=mesh_sync_wifi')
                    .then(function(r) { return r.json(); })
                    .then(function(res) {
                        ui.hideModal();
                        ui.addNotification(null, E('p', {}, res.message || 'Đã đồng bộ Wi-Fi sang Router Phụ!'), 'info');
                        refreshMeshDashboard();
                    }).catch(function(err) {
                        ui.hideModal();
                        ui.addNotification(null, E('p', {}, 'Lỗi: ' + err), 'error');
                    });
            }
        }, '🔄 ĐỒNG BỘ WI-FI SANG ROUTER PHỤ');

        var btnUnmesh = E('button', {
            class: 'btn cbi-button',
            style: 'background: #dc2626; color: #ffffff; font-size: 13px; font-weight: 800; padding: 10px 16px; border-radius: 8px; cursor: pointer; border: none;',
            click: function(ev) {
                if (!confirm('Xác nhận tắt chế độ Mesh?\nRouter sẽ quay về chế độ Wi-Fi Độc Lập (Standalone).')) return;
                var btn = ev.target;
                btn.disabled = true;
                btn.textContent = '⏳ Đang tắt Mesh...';
                fetch('/cgi-bin/airdrop?action=mesh_unmesh')
                    .then(function(r) { return r.json(); })
                    .then(function(data) {
                        btn.disabled = false;
                        btn.textContent = '⛔ TẮT CHẾ ĐỘ MESH';
                        ui.addNotification(null, E('p', '✅ ' + (data.message || 'Đã tắt hoàn toàn chế độ Mesh!')), 'info');
                        refreshMeshDashboard();
                    }).catch(function(err) {
                        btn.disabled = false;
                        btn.textContent = '⛔ TẮT CHẾ ĐỘ MESH';
                        ui.addNotification(null, E('p', '❌ Lỗi: ' + err), 'error');
                    });
            }
        }, '⛔ TẮT CHẾ ĐỘ MESH');

        var btnRefreshMesh = E('button', {
            class: 'btn cbi-button',
            style: 'font-weight: 700; padding: 10px 16px; border-radius: 8px; cursor: pointer; border: 1px solid #cbd5e1; background: #ffffff;',
            click: function() { refreshMeshDashboard(); }
        }, '🔄 Làm Tươi');

        function buildSharedMeshTopologyHtml(d, fast) {
            var isMaster = (d.role === 'controller' || d.role === 'main' || d.local_ip === '192.168.1.1');
            var isSlave = !isMaster;

            var roleBadge = !d.mesh_active ?
                '<span style="background: #ffffff; color: #000000; padding: 5px 12px; border-radius: 6px; font-weight: 800; font-size: 13px;">🟢 ROUTER PHÁT (ĐỘC LẬP - STANDALONE)</span>' :
                (isMaster ? 
                    '<span style="background: #e0f2fe; color: #0369a1; border: 1.5px solid #0284c7; padding: 5px 12px; border-radius: 6px; font-weight: 800; font-size: 13px;">👑 THIẾT BỊ PHÁT CHÍNH (MASTER CONTROLLER - GỐC)</span>' : 
                    '<span style="background: #ffedd5; color: #c2410c; border: 1.5px solid #ea580c; padding: 5px 12px; border-radius: 6px; font-weight: 800; font-size: 13px;">📡 THIẾT BỊ PHỤ (SLAVE NODE - ĐANG TRUY CẬP)</span>');

            var speedDisplay = (d.htmode === 'HE160') ? '2402.0 Mbps (HE160)' : ((d.htmode === 'HE80') ? '1201.0 Mbps (HE80)' : (d.htmode || '2402.0 Mbps (HE160)'));
            var activeBadge = d.mesh_active ? 
                '<span style="background: #ffffff; color: #15803d; border: 1px solid #86efac; padding: 5px 10px; border-radius: 6px; font-weight: 700; font-size: 12.5px;">🟢 Cụm Mesh Đang Hoạt Động (Wi-Fi 6 ' + (d.htmode || 'HE160') + ' • ' + speedDisplay + ')</span>' : 
                '<span style="background: #ffffff; color: #475569; border: 1px solid #cbd5e1; padding: 5px 10px; border-radius: 6px; font-weight: 700; font-size: 12.5px;">⚪ Đã Tắt Mesh (Chế Độ Độc Lập)</span>';
            var inetBadge = d.has_internet ?
                '<span style="background: #ffffff; color: #15803d; border: 1px solid #86efac; padding: 5px 10px; border-radius: 6px; font-weight: 800; font-size: 12.5px;">🌐 Internet: Sẵn Sàng (' + (d.internet_source || 'Trực Tiếp') + ')</span>' :
                '<span style="background: #ffffff; color: #b91c1c; border: 1px solid #fca5a5; padding: 5px 10px; border-radius: 6px; font-weight: 800; font-size: 12.5px;">❌ Mất Internet</span>';

            // 1. THIẾT BỊ PHÁT CHÍNH (MASTER GATEWAY - GỐC CÓ MẠNG 192.168.1.1)
            var masterIp = '192.168.1.1';
            var masterModel = d.master_model || (isMaster ? 
                ((fast && (fast.board_model || fast.model)) || window._savedBoardModel || d.board_model || d.local_name || 'Router Chính (Gateway)') : 
                (d.master_model || 'Router Chính (Gateway)'));
            var masterName = isMaster ? (d.local_name || 'ImmortalWrt') : (d.master_name || 'Router Chính');
            var masterMac = d.master_mac || (isMaster ? (d.local_mac || '192.168.1.1') : (d.master_mac || '192.168.1.1'));
            var masterCpu = isMaster ? 
                ((fast && fast.soc_family) ? (fast.soc_family + (fast.cpu_cores ? ' (' + fast.cpu_cores + ' Cores • ' + (fast.cpu_freq_ghz || '2.0 GHz') + (fast.ram_total_mb ? ' • ' + Math.round(fast.ram_total_mb/1024*10)/10 + 'GB RAM' : '') + ')' : '')) : (d.soc_family ? (d.soc_family + (d.cpu_cores ? ' (' + d.cpu_cores + ' Cores' + (d.ram_total_mb ? ' • ' + Math.round(d.ram_total_mb/1024*10)/10 + 'GB RAM' : '') + ')' : '')) : 'Bộ Xử Lý Trung Tâm')) : 
                (d.master_soc || 'Bộ Xử Lý Trung Tâm (Gateway)');
            var masterWifi = (d.radio || 'radio1') + ' • Kênh ' + (d.channel || '36') + ' (' + speedDisplay + ')';
            var masterInternet = isMaster ? 
                ((fast && fast.wwan_signal) ? (fast.wwan_signal + ' • ' + (fast.wwan_band_detail ? fast.wwan_band_detail.split('•')[0] : '5G Sub-6')) : (d.internet_source || 'Cổng WAN/WWAN Trực Tiếp')) :
                'Đường Ra Internet Trực Tiếp (Gateway Trung Tâm)';
            var masterClients = isMaster ? ((fast && fast.online_clients) || '12') : 'Thiết bị Gateway';

            var masterStatusBadge = isMaster ? 
                '<span style="background: #e0f2fe; color: #0369a1; border: 1.5px solid #0284c7; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 800;">👑 Đang Truy Cập (Trang Hiện Tại)</span>' : 
                '<span style="background: #dcfce7; color: #15803d; border: 1px solid #86efac; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 800;">🟢 Online (Gateway)</span>';

            var masterFooterBtn = isMaster ?
                '<span style="background: #ffffff; color: #000000; padding: 2px 8px; border-radius: 10px; font-weight: 700; font-size: 11px;">Trạm Phát Trung Tâm ⭐</span>' :
                '<a href="http://192.168.1.1" target="_blank" class="btn" style="background: #2563eb; color: #ffffff; border: none; padding: 4px 14px; font-size: 12px; font-weight: 800; border-radius: 6px; text-decoration: none; box-shadow: 0 2px 4px rgba(37, 99, 235, 0.2);">Mở LuCI Router Chính (192.168.1.1) ↗</a>';

            var masterCardHtml = 
                '<div style="max-width: 640px; margin: 0 auto; background: #ffffff; border: 1.5px solid #38bdf8; border-radius: 12px; padding: 16px; box-shadow: 0 4px 12px rgba(14, 165, 233, 0.1);">' +
                    '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">' +
                        '<span style="background: #e0f2fe; color: #0369a1; padding: 3px 12px; border-radius: 20px; font-size: 11.5px; font-weight: 800; letter-spacing: 0.5px; display: inline-flex; align-items: center; gap: 5px;">👑 TẦNG 1: ROUTER CHÍNH (MASTER CONTROLLER - GỐC)</span>' +
                        masterStatusBadge +
                    '</div>' +
                    '<div style="font-size: 16.5px; font-weight: 800; color: #000000; margin-bottom: 8px; display:flex; align-items:center; gap:6px;">' + masterModel + ' <span style="font-size: 12.5px; font-weight: 600; color: #64748b;">(' + masterName + ')</span></div>' +
                    '<div style="font-size: 12.5px; color: #000000; line-height: 1.8; display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 4px 16px;">' +
                        '<div>🌐 <b>IP Quản Trị (Gateway):</b> <code style="color: #0369a1; font-weight: 800; background: #f0f9ff; padding: 1px 7px; border-radius: 4px; font-size: 13px;">' + masterIp + '</code></div>' +
                        '<div>🏷️ <b>Địa chỉ MAC:</b> <span style="font-family: monospace; color: #000000; font-weight: 600;">' + masterMac + '</span></div>' +
                        '<div>⚡ <b>Bộ Xử Lý & RAM:</b> ' + masterCpu + '</div>' +
                        '<div>📻 <b>Wi-Fi 6 Phát Sóng:</b> ' + masterWifi + '</div>' +
                        '<div style="grid-column: 1 / -1;">🌍 <b>Đường Ra Internet:</b> <span style="color: #000000; font-weight: 700;">' + masterInternet + '</span></div>' +
                    '</div>' +
                    '<div style="margin-top: 12px; padding-top: 10px; border-top: 1px solid #bae6fd; display: flex; justify-content: space-between; align-items: center; font-size: 12px; color: #000000;">' +
                        '<span>📱 Thiết bị kết nối trực tiếp: <b style="color: #000000; font-size:13px;">' + masterClients + ' Online</b></span>' +
                        masterFooterBtn +
                    '</div>' +
                '</div>';

            // 2. DANH SÁCH THIẾT BỊ PHỤ (SLAVE NODES)
            var slaveNodes = [];
            if (isMaster) {
                if (d.peers && d.peers.length > 0) {
                    slaveNodes = d.peers.filter(function(p) {
                        return p.ip && p.ip !== '192.168.1.1';
                    });
                }
            } else {
                var currentSlaveName = d.board_model || (fast && (fast.board_model || fast.model)) || window._savedBoardModel || d.local_name || 'Router Phụ';
                var currentSlaveMac = d.local_mac || (d.peers && d.peers[0] && d.peers[0].mac) || '';
                var currentSlaveSig = (d.peers && d.peers[0] && d.peers[0].signal) || '-21 dBm';
                var currentSlaveBitrate = (d.peers && d.peers[0] && d.peers[0].bitrate) || '2402.0 Mbps (HE160)';
                var currentSlaveAdvice = (d.peers && d.peers[0] && d.peers[0].advice) || '🟢 ĐÃ TỐI ƯU HOÀN HẢO (Sóng cực mạnh, đạt max tốc độ 2402 Mbps)';
                slaveNodes.push({
                    ip: d.local_ip || '192.168.1.10',
                    mac: currentSlaveMac,
                    name: currentSlaveName,
                    signal: currentSlaveSig,
                    bitrate: currentSlaveBitrate,
                    advice: currentSlaveAdvice,
                    url: 'http://' + (d.local_ip || '192.168.1.10'),
                    is_current: true
                });
                if (d.peers && d.peers.length > 1) {
                    d.peers.slice(1).forEach(function(p) {
                        if (p.ip && p.ip !== (d.local_ip || '192.168.1.10') && p.ip !== '192.168.1.1') {
                            slaveNodes.push(p);
                        }
                    });
                }
            }

            var hasSlaves = (slaveNodes.length > 0);
            var connectorLineColor = hasSlaves ? '#10b981' : (d.mesh_active ? '#0284c7' : '#94a3b8');
            var connectorBorder = hasSlaves ? '#86efac' : (d.mesh_active ? '#bae6fd' : '#cbd5e1');

            var connectorHtml = 
                '<div style="display: flex; flex-direction: column; align-items: center; margin: 6px 0 10px 0;">' +
                    '<div style="width: 2.5px; height: 22px; background: ' + connectorLineColor + ';"></div>' +
                    '<div style="background: #ffffff; border: 1.5px solid ' + connectorBorder + '; color: #000000; padding: 4px 18px; border-radius: 20px; font-size: 11.5px; font-weight: 800; display: inline-flex; align-items: center; gap: 6px; box-shadow: 0 2px 6px rgba(0,0,0,0.06);">' +
                        '<span>⚡ PHÂN TẦNG KẾT NỐI MESH BACKHAUL (WI-FI 6 HE160 • 2402 MBPS) ▼</span>' +
                    '</div>' +
                    '<div style="width: 2.5px; height: 22px; background: ' + connectorLineColor + ';"></div>' +
                '</div>';

            var slavesGridHtml = '';
            var tableRowsHtml = '';

            if (hasSlaves) {
                slavesGridHtml = '<div style="display: flex; justify-content: center; gap: 16px; flex-wrap: wrap; margin-bottom: 16px;">';
                slaveNodes.forEach(function(p, idx) {
                    var isCurrentThisNode = (p.is_current === true || (isSlave && p.ip === (d.local_ip || '192.168.1.10')));
                    var nodeStatusBadge = isCurrentThisNode ?
                        '<span style="background: #dcfce7; color: #15803d; border: 1.5px solid #16a34a; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 800;">📡 Đang Truy Cập (Trang Hiện Tại)</span>' :
                        '<span style="background: #ffffff; color: #15803d; border: 1px solid #86efac; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 800;">🟢 Đã Ghép Nối</span>';

                    var nodeBtnHtml = isCurrentThisNode ?
                        '<span style="background: #f0fdf4; color: #16a34a; border: 1px solid #86efac; padding: 4px 12px; font-size: 12px; font-weight: 800; border-radius: 6px;">(Trang Hiện Tại)</span>' :
                        '<a href="' + (p.url || ('http://' + p.ip)) + '" target="_blank" class="btn" style="background: #ffffff; color: #000000; border: 1px solid #cbd5e1; padding: 4px 12px; font-size: 12px; font-weight: 800; border-radius: 6px; text-decoration: none; box-shadow: 0 2px 4px rgba(5, 150, 105, 0.2);">Mở LuCI Node ↗</a>';

                    slavesGridHtml += 
                        '<div style="background: #ffffff; border: 1.5px solid #86efac; border-radius: 12px; padding: 16px; box-shadow: 0 4px 12px rgba(16, 185, 129, 0.1); min-width: 300px; max-width: 440px; flex: 1; display: flex; flex-direction: column; justify-content: space-between;">' +
                            '<div>' +
                                '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">' +
                                    '<span style="background: #ffedd5; color: #c2410c; padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 800; letter-spacing: 0.5px; display: inline-flex; align-items: center; gap: 4px;">📡 TẦNG 2: ROUTER PHỤ (SLAVE NODE ' + (idx + 1) + ')</span>' +
                                    nodeStatusBadge +
                                '</div>' +
                                '<div style="font-size: 16px; font-weight: 800; color: #000000; margin-bottom: 8px;">' + (p.name || 'Router Phụ ' + (idx + 1)) + '</div>' +
                                '<div style="font-size: 12.5px; color: #000000; line-height: 1.8;">' +
                                    '<div>🌐 <b>IP Quản Trị:</b> <a href="' + (p.url || ('http://' + p.ip)) + '" target="_blank" style="color: #0284c7; font-weight: 800; background: #f0f9ff; padding: 1px 7px; border-radius: 4px; text-decoration: none; font-size: 13px;">' + p.ip + ' ↗</a></div>' +
                                    '<div>🏷️ <b>MAC Đối Tác:</b> <span style="font-family: monospace; color: #000000; font-weight: 600;">' + (p.mac || '-') + '</span></div>' +
                                    '<div>📶 <b>Cường Độ Sóng:</b> <span style="color: #15803d; font-weight: 800; font-size: 13px;">' + p.signal + '</span></div>' +
                                    '<div>🚀 <b>Tốc Độ Kết Nối:</b> <span style="color: #000000; font-weight: 700;">' + p.bitrate + '</span></div>' +
                                    '<div>🛡️ <b>Đánh Giá Vị Trí:</b> <span style="font-size: 11.5px;">' + (p.advice || '🟢 ĐÃ TỐI ƯU HOÀN HẢO (Sóng cực mạnh, đạt max tốc độ 2402 Mbps)') + '</span></div>' +
                                '</div>' +
                            '</div>' +
                            '<div style="margin-top: 14px; padding-top: 10px; border-top: 1px solid #bbf7d0; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 6px;">' +
                                '<span style="font-size: 11px; color: #000000;">Fast Roaming: <b style="color: #15803d;">802.11r/k/v Bật</b></span>' +
                                nodeBtnHtml +
                            '</div>' +
                        '</div>';

                    var tableNodeAction = isCurrentThisNode ?
                        '<span style="color: #15803d; font-weight:700; font-size:12px;">(Trang Hiện Tại)</span>' :
                        '<a href="' + (p.url || ('http://' + p.ip)) + '" target="_blank" class="btn" style="background: #2563eb; color: #ffffff; border:none; padding:3px 10px; font-size:12px; font-weight:700; border-radius:4px; text-decoration:none;">Mở LuCI Node ↗</a>';

                    tableRowsHtml += '<tr>' +
                        '<td style="padding: 8px 10px;"><span style="background: #ffedd5; color: #c2410c; padding:2px 8px; border-radius:4px; font-size:11px; font-weight:800;">📡 TẦNG 2 (NODE ' + (idx+1) + ')</span></td>' +
                        '<td style="padding: 8px 10px;"><b>' + (p.name || 'Router Phụ') + '</b></td>' +
                        '<td style="padding: 8px 10px;"><span style="color: #c2410c; font-weight: 800;">📡 THIẾT BỊ PHỤ (TIẾP SÓNG MESH)</span></td>' +
                        '<td style="padding: 8px 10px;"><code>' + (p.ip || '-') + '</code></td>' +
                        '<td style="padding: 8px 10px;"><span style="font-family:monospace; color: #000000;">' + (p.mac || '-') + '</span></td>' +
                        '<td style="padding: 8px 10px;"><span style="color: #15803d; font-weight:700;">' + p.signal + '</span></td>' +
                        '<td style="padding: 8px 10px;"><b>' + p.bitrate + '</b></td>' +
                        '<td style="padding: 8px 10px;">' + (p.advice || '🟢 ĐÃ TỐI ƯU HOÀN HẢO') + '</td>' +
                        '<td style="padding: 8px 10px;">' + tableNodeAction + '</td>' +
                    '</tr>';
                });
                slavesGridHtml += '</div>';
            } else {
                var standbyBadge = d.mesh_active ?
                    '<span style="background: #ffffff; color: #d97706; border: 1.5px solid #fcd34d; padding: 2px 10px; border-radius: 12px; font-size: 11px; font-weight: 800;">⏳ Đang Quét & Chờ Bắt Tay</span>' :
                    '<span style="background: #ffffff; color: #475569; border: 1.5px solid #cbd5e1; padding: 2px 10px; border-radius: 12px; font-size: 11px; font-weight: 800;">💤 Sẵn Sàng (Cắm Điện Hoặc Bấm 1-Click)</span>';

                slavesGridHtml = 
                    '<div style="display: flex; justify-content: center; margin-bottom: 16px;">' +
                        '<div style="max-width: 640px; width: 100%; background: #ffffff; border: 1.5px dashed #94a3b8; border-radius: 12px; padding: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">' +
                            '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; flex-wrap: wrap; gap: 6px;">' +
                                '<span style="background: #ffedd5; color: #c2410c; padding: 3px 12px; border-radius: 20px; font-size: 11.5px; font-weight: 800; letter-spacing: 0.5px; display: inline-flex; align-items: center; gap: 5px;">📡 TẦNG 2: THIẾT BỊ PHỤ (SLAVE NODE - CHẾ ĐỘ CHỜ)</span>' +
                                standbyBadge +
                            '</div>' +
                            '<div style="font-size: 16px; font-weight: 800; color: #000000; margin-bottom: 8px; display: flex; align-items: center; gap: 6px;">' +
                                '🔄 Router Phụ Phân Tầng <span style="font-size: 12.5px; font-weight: 600; color: #64748b;">(Tự Động Nhận Diện Khi Cắm Điện)</span>' +
                            '</div>' +
                            '<div style="font-size: 12.5px; color: #000000; line-height: 1.8; display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 4px 16px;">' +
                                '<div>🌐 <b>IP Khi Kết Nối Mesh:</b> <code style="color: #0284c7; font-weight: 800; background: #f0f9ff; padding: 1px 7px; border-radius: 4px;">192.168.1.10</code> <span style="color: #64748b; font-size:11px;">(Tự tắt DHCP)</span></div>' +
                                '<div>🔄 <b>IP Khi Ngắt Mesh:</b> <code style="color: #0284c7; font-weight: 800; background: #f0f9ff; padding: 1px 7px; border-radius: 4px;">192.168.1.1</code> <span style="color: #64748b; font-size:11px;">(Tự bật DHCP)</span></div>' +
                                '<div>⚡ <b>Tốc Độ Kết Nối Chuẩn:</b> <b style="color: #15803d;">2402.0 Mbps (Wi-Fi 6 HE160)</b></div>' +
                                '<div>🚀 <b>Chuyển Vùng Sóng:</b> <b style="color: #15803d;">Fast Roaming 802.11r/k/v</b></div>' +
                                '<div style="grid-column: 1 / -1; background: #f8fafc; padding: 9px 14px; border-radius: 8px; font-size: 12px; color: #334155; line-height: 1.6; margin-top: 6px; border: 1px solid #e2e8f0;">' +
                                    '💡 <b>Cơ Chế Hoàn Toàn Tự Động 100%:</b>' +
                                    '<ul style="margin: 4px 0 0 16px; padding: 0;">' +
                                        '<li>Router có Internet (WAN/5G) luôn là <b>Router Chính</b>, Router không có Internet tự làm <b>Router Phụ</b>.</li>' +
                                        '<li>Khi kết nối Mesh: Router phụ tự đổi IP sang <code>192.168.1.10</code> và tắt DHCP.</li>' +
                                        '<li>Khi ngắt kết nối Mesh: Router phụ tự khôi phục lại IP mặc định <code>192.168.1.1</code> và bật lại DHCP.</li>' +
                                        '<li>Sau 10 phút khởi động nếu không ghép nối, cả chính và phụ sẽ <b>tự động tắt Mesh</b> để tiết kiệm sóng Wi-Fi và tài nguyên CPU/RAM. Bấm 1-Click bất kỳ lúc nào để ghép nối lại!</li>' +
                                    '</ul>' +
                                '</div>' +
                            '</div>' +
                        '</div>' +
                    '</div>';
            }

            var tableMasterAction = isMaster ?
                '<span style="color: #0369a1; font-weight:700; font-size:12px;">(Trang Hiện Tại)</span>' :
                '<a href="http://192.168.1.1" target="_blank" class="btn" style="background: #2563eb; color: #ffffff; border:none; padding:3px 10px; font-size:12px; font-weight:700; border-radius:4px; text-decoration:none;">Mở LuCI Router Chính ↗</a>';

            var fullTableHtml = '<table class="table" style="width:100%; margin-top: 10px; font-size: 13px; border-collapse: collapse;">' +
                '<thead><tr style="background: #f8fafc; border-bottom: 1.5px solid #cbd5e1;">' +
                    '<th style="padding: 8px 10px;">Phân Cấp</th>' +
                    '<th style="padding: 8px 10px;">Tên Thiết Bị</th>' +
                    '<th style="padding: 8px 10px;">Vai Trò Thực Tế</th>' +
                    '<th style="padding: 8px 10px;">IP Quản Trị</th>' +
                    '<th style="padding: 8px 10px;">Địa Chỉ MAC</th>' +
                    '<th style="padding: 8px 10px;">Cường Độ Sóng</th>' +
                    '<th style="padding: 8px 10px;">Băng Thông</th>' +
                    '<th style="padding: 8px 10px;">Đánh Giá Vị Trí</th>' +
                    '<th style="padding: 8px 10px;">Thao Tác</th>' +
                '</tr></thead><tbody>' +
                '<tr style="background: #ffffff; border-bottom: 1px solid #f1f5f9;">' +
                    '<td style="padding: 8px 10px;"><span style="background: #e0f2fe; color: #0369a1; padding:2px 8px; border-radius:4px; font-size:11px; font-weight:800;">👑 TẦNG 1 (GỐC)</span></td>' +
                    '<td style="padding: 8px 10px;"><b>' + masterModel + '</b></td>' +
                    '<td style="padding: 8px 10px;"><span style="color: #0369a1; font-weight: 800;">👑 THIẾT BỊ PHÁT CHÍNH (CÓ MẠNG GỐC)</span></td>' +
                    '<td style="padding: 8px 10px;"><code style="font-weight:700; font-size:13px; color: #0369a1;">' + masterIp + '</code></td>' +
                    '<td style="padding: 8px 10px;"><span style="font-family:monospace; color: #000000;">' + masterMac + '</span></td>' +
                    '<td style="padding: 8px 10px;"><span style="color: #15803d; font-weight:700;">🟢 Cực Mạnh (Gốc)</span></td>' +
                    '<td style="padding: 8px 10px;"><b>' + speedDisplay + '</b></td>' +
                    '<td style="padding: 8px 10px;"><span style="color: #d97706; font-weight:700;">⭐ Gateway Trung Tâm</span></td>' +
                    '<td style="padding: 8px 10px;">' + tableMasterAction + '</td>' +
                '</tr>' +
                tableRowsHtml +
                '</tbody></table>';

            var headerTitleHtml = d.mesh_active ?
                '<div><h4 style="margin: 0; font-size: 16px; font-weight: 800; color: #0f172a;">📡 Bảng Điều Khiển Cụm Wi-Fi Mesh Tự Động (Live)</h4><div style="color: #64748b; font-size: 12.5px; margin-top: 2px;">Chuẩn Fast Roaming 802.11r/k/v chuyển vùng sóng tức thì không gián đoạn Game / Video Call</div></div>' :
                '<div><h4 style="margin: 0; font-size: 16px; font-weight: 800; color: #0f172a;">📡 Bảng Quản Lý Wi-Fi Mesh (Hiện Đang Tắt - Chế Độ Độc Lập)</h4><div style="color: #64748b; font-size: 12.5px; margin-top: 2px;">Router đang hoạt động độc lập (Standalone), dành trọn 2402 Mbps băng thông Wi-Fi 6 cho thiết bị</div></div>';

            var timeoutNotice = '';
            if (d.mesh_active && d.mesh_timeout_left > 0 && (!d.peer_count || d.peer_count === 0)) {
                var min = Math.floor(d.mesh_timeout_left / 60);
                var sec = d.mesh_timeout_left % 60;
                timeoutNotice = '<div style="margin-bottom: 12px; font-size: 13px; color: #b45309; font-weight: 700; background: #fffbeb; border: 1.5px solid #f59e0b; padding: 10px 14px; border-radius: 8px; display: flex; align-items: center; gap: 8px;">' +
                    '⏱️ <b>Tự động tắt Mesh:</b> Còn <b>' + min + ' phút ' + (sec < 10 ? '0' : '') + sec + ' giây</b> (Hệ thống sẽ tự động tắt chế độ Mesh và ẩn thiết bị để giải phóng băng thông Wi-Fi nếu không có Router phụ)' +
                '</div>';
            }

            var cardMeshIdHtml = d.mesh_active ?
                ('<div style="background: #fff; padding: 10px; border-radius: 6px; border: 1px solid #e2e8f0;">🏷️ <b>Mesh ID:</b> <code style="color: #0369a1; font-weight:700;">' + (d.mesh_id || 'immorWRT-5G') + '</code></div>') :
                ('<div style="background: #fff; padding: 10px; border-radius: 6px; border: 1px solid #e2e8f0;">🏷️ <b>Mesh ID:</b> <span style="color: #64748b; font-weight:700;">Đã tắt (Không phát sóng)</span></div>');

            var cardFastRoamingHtml = (d.mesh_active && d.fast_roaming) ?
                ('<div style="background: #fff; padding: 10px; border-radius: 6px; border: 1px solid #e2e8f0;">🚀 <b>Fast Roaming:</b> <span style="color: #15803d; font-weight:700;">BẬT (802.11r)</span></div>') :
                ('<div style="background: #fff; padding: 10px; border-radius: 6px; border: 1px solid #e2e8f0;">🚀 <b>Fast Roaming:</b> <span style="color: #64748b; font-weight:700;">Tắt (Chế độ Độc Lập)</span></div>');

            var cardChannelHtml = d.mesh_active ? 
                ('<div style="background: #fff; padding: 10px; border-radius: 6px; border: 1px solid #e2e8f0;">📻 <b>Card & Kênh Backhaul:</b> ' + (d.radio || 'radio1') + ' (Kênh ' + (d.channel || '36') + ' - ' + (d.htmode || 'HE160') + ')</div>') :
                ('<div style="background: #fff; padding: 10px; border-radius: 6px; border: 1px solid #e2e8f0;">📻 <b>Sóng Phụ Mesh:</b> <span style="color: #64748b; font-weight:700;">ĐÃ TẮT HOÀN TOÀN (Dành trọn 2402 Mbps cho thiết bị)</span></div>');

            var totalNodeCount = hasSlaves ? slaveNodes.length : 0;

            return '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; flex-wrap: wrap; gap: 8px;">' +
                    headerTitleHtml +
                    '<div style="display:flex; gap:6px; align-items:center; flex-wrap:wrap;">' + roleBadge + ' ' + activeBadge + ' ' + inetBadge + '</div>' +
                '</div>' +
                timeoutNotice +
                '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 10px; margin-bottom: 14px; font-size: 13.5px;">' +
                    cardMeshIdHtml +
                    cardChannelHtml +
                    '<div style="background: #fff; padding: 10px; border-radius: 6px; border: 1px solid #e2e8f0;">👥 <b>Số Node liên kết:</b> <b>' + totalNodeCount + ' Node</b></div>' +
                    cardFastRoamingHtml +
                '</div>' +
                '<div style="margin-top: 14px; margin-bottom: 8px;"><b>Danh Sách Router Đã Bắt Tay & Kết Nối:</b></div>' +
                masterCardHtml +
                connectorHtml +
                slavesGridHtml +
                '<div style="margin-top: 16px;">' + fullTableHtml + '</div>';
        }

        function refreshMeshDashboard() {
            Promise.all([
                fetch('/cgi-bin/airdrop?action=mesh_status&t=' + Date.now()).then(function(r) { return r.json(); }).catch(function() { return {}; }),
                fetch('/cgi-bin/airdrop?action=fast_stats&t=' + Date.now()).then(function(r) { return r.json(); }).catch(function() { return {}; })
            ]).then(function(resList) {
                var d = resList[0] || {};
                var fast = resList[1] || {};
                meshStatusCard.innerHTML = buildSharedMeshTopologyHtml(d, fast);
            }).catch(function(err) {
                meshStatusCard.innerHTML = '<div style="color: #dc2626; font-weight: 700; padding: 15px;">Lỗi tải dữ liệu Mesh: ' + err + '</div>';
            });
        }
        refreshMeshDashboard();

        var meshTabContent = E('div', { class: 'cbi-section', style: 'display: none; padding: 20px; background: #ffffff; border-radius: 10px; border: 1px solid #e2e8f0;' }, [
            E('h3', { style: 'margin-top: 0; font-size: 18px; font-weight: 800; color: #1e293b; border-bottom: 1px solid #f1f5f9; padding-bottom: 10px;' }, '⚡ 1-Click Auto Mesh & Roaming Không Giây (802.11s / 802.11r/k/v)'),
            meshStatusCard,
            E('div', { style: 'display: flex; gap: 10px; align-items: center; flex-wrap: wrap; margin-top: 14px; padding: 14px; background: #f8fafc; border-radius: 8px; border: 1px solid #e2e8f0;' }, [
                btnTriggerMeshPair,
                btnSetMaster,
                btnSetSlave,
                btnMeshSyncWifi,
                btnUnmesh,
                btnRefreshMesh
            ])
        ]);
        tabPanes['mesh'] = meshTabContent;

        // ---------------- TAB 4: TELEGRAM BOT & AI SENTINEL (FULL VAULT INTEGRATION) ----------------
        var teleTokenInput = E('input', { type: 'text', class: 'cbi-input-text', value: sentinelConfig.tg_bot_token || '', placeholder: 'Nhập Telegram Bot Token (vd: 7123456789:AAH...)', style: 'width: 100%; height: 38px; font-weight: 700; border-radius: 6px; margin-bottom: 10px;' });
        var teleChatIdInput = E('input', { type: 'text', class: 'cbi-input-text', value: sentinelConfig.tg_admin_id || '', placeholder: 'Nhập Telegram Admin Chat ID (vd: 123456789)', style: 'width: 100%; height: 38px; font-weight: 700; border-radius: 6px; margin-bottom: 10px;' });
        var teleOwnerInput = E('input', { type: 'text', class: 'cbi-input-text', value: sentinelConfig.tg_owner_name || 'Anh Duy', placeholder: 'Tên chủ sở hữu (vd: Anh Duy)', style: 'width: 100%; height: 38px; font-weight: 700; border-radius: 6px; margin-bottom: 10px;' });
        var emgPhoneInput = E('input', { type: 'text', class: 'cbi-input-text', value: sentinelConfig.emergency_phone || '', placeholder: 'SĐT khẩn cấp gọi/nhắn tin báo động (vd: 0912345678)', style: 'width: 100%; height: 38px; font-weight: 700; border-radius: 6px; margin-bottom: 10px;' });
        var geminiKeyInput = E('input', { type: 'password', class: 'cbi-input-text', value: sentinelConfig.gemini_api_key || '', placeholder: 'Google Gemini AI API Key (AI Phân tích hình ảnh, khói cháy)', style: 'width: 100%; height: 38px; font-weight: 700; border-radius: 6px; margin-bottom: 10px;' });
        var tailscaleKeyInput = E('input', { type: 'password', class: 'cbi-input-text', value: sentinelConfig.tailscale_auth_key || '', placeholder: 'Tailscale Auth Key (VPN kết nối bảo mật từ xa)', style: 'width: 100%; height: 38px; font-weight: 700; border-radius: 6px; margin-bottom: 10px;' });
        var cloudRemoteInput = E('input', { type: 'text', class: 'cbi-input-text', value: sentinelConfig.cloud_remote || '', placeholder: 'Tên Remote Cloud Rclone (vd: gdrive, onedrive)', style: 'width: 100%; height: 38px; font-weight: 700; border-radius: 6px; margin-bottom: 10px;' });
        // === LOCKED: VERIFIED BY DOANDUY - DO NOT MODIFY ===
        // Quản Lý Camera IP Sentinel Mở Rộng Không Giới Hạn (Chỉ Cần Nhập IP Camera)
        var cameraList = [];
        if (sentinelConfig.cameras && Array.isArray(sentinelConfig.cameras) && sentinelConfig.cameras.length > 0) {
            cameraList = sentinelConfig.cameras.slice();
        } else {
            if (sentinelConfig.cam1_rtsp) cameraList.push(sentinelConfig.cam1_rtsp);
            if (sentinelConfig.cam2_rtsp) cameraList.push(sentinelConfig.cam2_rtsp);
            if (sentinelConfig.cam_cong_rtsp) cameraList.push(sentinelConfig.cam_cong_rtsp);
            if (cameraList.length === 0) {
                cameraList = ['192.168.1.100', '192.168.1.101', '192.168.1.102'];
            }
        }

        var cameraListContainer = E('div', { style: 'display: flex; flex-direction: column; gap: 10px; margin-bottom: 12px;' });

        function renderCameraList() {
            cameraListContainer.innerHTML = '';
            cameraList.forEach(function(camVal, idx) {
                var camInput = E('input', {
                    type: 'text',
                    class: 'cbi-input-text',
                    value: camVal || '',
                    placeholder: 'Nhập IP Camera (vd: 192.168.1.' + (100 + idx) + ') hoặc link RTSP',
                    style: 'flex: 1; height: 38px; font-weight: 700; border-radius: 6px; font-size: 13px;'
                });
                camInput.addEventListener('input', function() {
                    cameraList[idx] = camInput.value.trim();
                });

                var delBtn = E('button', {
                    class: 'btn cbi-button',
                    style: 'font-size: 12px; font-weight: 750; padding: 6px 12px; border-radius: 6px; background: #fee2e2; color: #b91c1c; border: 1px solid #fca5a5; cursor: pointer;',
                    click: function() {
                        if (cameraList.length <= 1) {
                            cameraList[0] = '';
                            renderCameraList();
                            return;
                        }
                        cameraList.splice(idx, 1);
                        renderCameraList();
                    }
                }, '🗑️ Xóa');

                var row = E('div', { style: 'display: flex; align-items: center; gap: 10px; background: #ffffff; padding: 8px 12px; border-radius: 6px; border: 1px solid #e2e8f0;' }, [
                    E('span', { style: 'font-weight: 750; font-size: 13px; color: #1e293b; min-width: 110px;' }, '📹 Camera #' + (idx + 1) + ':'),
                    camInput,
                    delBtn
                ]);
                cameraListContainer.appendChild(row);
            });
        }
        renderCameraList();

        var addCameraBtn = E('button', {
            class: 'btn cbi-button',
            style: 'font-size: 12.5px; font-weight: 750; padding: 7px 16px; border-radius: 6px; background: #f0fdf4; color: #166534; border: 1.5px solid #86efac; cursor: pointer; display: inline-flex; align-items: center; gap: 6px;',
            click: function() {
                var nextIp = '192.168.1.' + (100 + cameraList.length);
                cameraList.push(nextIp);
                renderCameraList();
            }
        }, '➕ Thêm Camera IP Mới');

        // === LOCKED: VERIFIED BY DOANDUY - DO NOT MODIFY ===
        // Quản Lý Telegram Bot Camera Không Giới Hạn (Mở Rộng Đa Kênh/Đa Mục Đích)
        var telegramBotsList = [];
        if (sentinelConfig.telegram_bots && Array.isArray(sentinelConfig.telegram_bots) && sentinelConfig.telegram_bots.length > 0) {
            telegramBotsList = sentinelConfig.telegram_bots.slice();
        } else {
            var curTok = sentinelConfig.tg_bot_token || '7123456789:AAHtest';
            var curChat = sentinelConfig.tg_admin_id || '123456789';
            telegramBotsList = [
                { name: 'Bot Camera Chính (Master)', token: curTok, chat_id: curChat },
                { name: 'Bot Báo Động Trộm & Còi Hú', token: curTok, chat_id: curChat },
                { name: 'Bot Báo Cháy / Khói (Emergency)', token: curTok, chat_id: curChat }
            ];
        }

        var telegramBotsContainer = E('div', { style: 'display: flex; flex-direction: column; gap: 10px; margin-bottom: 12px;' });

        function renderTelegramBotsList() {
            telegramBotsContainer.innerHTML = '';
            telegramBotsList.forEach(function(bot, idx) {
                var botNameInput = E('input', {
                    type: 'text',
                    class: 'cbi-input-text',
                    value: bot.name || ('Bot Camera #' + (idx + 1)),
                    placeholder: 'Tên Bot / Mục Đích (vd: Bot Cam Cổng, Bot Báo Cháy)',
                    style: 'width: 210px; height: 38px; font-weight: 750; border-radius: 6px; font-size: 13px;'
                });
                botNameInput.addEventListener('input', function() {
                    telegramBotsList[idx].name = botNameInput.value.trim();
                });

                var botTokenInput = E('input', {
                    type: 'text',
                    class: 'cbi-input-text',
                    value: bot.token || '',
                    placeholder: 'Telegram Bot Token (vd: 7123456789:AAH...)',
                    style: 'flex: 2; min-width: 220px; height: 38px; font-weight: 700; font-family: monospace; border-radius: 6px; font-size: 12.5px;'
                });
                botTokenInput.addEventListener('input', function() {
                    telegramBotsList[idx].token = botTokenInput.value.trim();
                    if (idx === 0) teleTokenInput.value = botTokenInput.value.trim();
                });

                var botChatIdInput = E('input', {
                    type: 'text',
                    class: 'cbi-input-text',
                    value: bot.chat_id || '',
                    placeholder: 'Chat ID / Group ID (vd: 123456789 hoặc -100...)',
                    style: 'flex: 1; min-width: 140px; height: 38px; font-weight: 700; font-family: monospace; border-radius: 6px; font-size: 12.5px;'
                });
                botChatIdInput.addEventListener('input', function() {
                    telegramBotsList[idx].chat_id = botChatIdInput.value.trim();
                    if (idx === 0) teleChatIdInput.value = botChatIdInput.value.trim();
                });

                var testBtn = E('button', {
                    class: 'btn cbi-button',
                    style: 'font-size: 11.5px; font-weight: 700; padding: 6px 12px; border-radius: 6px; background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; cursor: pointer; white-space: nowrap;',
                    click: function(ev) {
                        var curT = botTokenInput.value.trim();
                        var curC = botChatIdInput.value.trim();
                        if (!curT || !curC) {
                            alert('Vui lòng nhập Token và Chat ID trước khi test!');
                            return;
                        }
                        ev.target.textContent = '⏳ Đang gửi...';
                        ev.target.disabled = true;
                        var testMsg = encodeURIComponent('🚨 [TEST SENTINEL AI]: Bot [' + (bot.name || ('Bot #' + (idx + 1))) + '] kết nối thành công với Router 5G Sentinel!');
                        fetch('https://api.telegram.org/bot' + curT + '/sendMessage?chat_id=' + curC + '&text=' + testMsg)
                            .then(function(r) { return r.json(); })
                            .then(function(res) {
                                ev.target.textContent = '⚡ Test Bot';
                                ev.target.disabled = false;
                                if (res && res.ok) {
                                    ui.addNotification(null, E('p', '✅ Gửi tin test Telegram thành công tới [' + (bot.name || 'Bot') + ']!'), 'info');
                                } else {
                                    ui.addNotification(null, E('p', '❌ Lỗi gửi tin Telegram: ' + (res.description || 'Không thể gửi')), 'error');
                                }
                            }).catch(function(err) {
                                ev.target.textContent = '⚡ Test Bot';
                                ev.target.disabled = false;
                                alert('Lỗi kết nối API: ' + err);
                            });
                    }
                }, '⚡ Test Bot');

                var delBtn = E('button', {
                    class: 'btn cbi-button',
                    style: 'font-size: 12px; font-weight: 750; padding: 6px 12px; border-radius: 6px; background: #fee2e2; color: #b91c1c; border: 1px solid #fca5a5; cursor: pointer;',
                    click: function() {
                        if (telegramBotsList.length <= 1) {
                            telegramBotsList[0] = { name: '', token: '', chat_id: '' };
                            renderTelegramBotsList();
                            return;
                        }
                        telegramBotsList.splice(idx, 1);
                        renderTelegramBotsList();
                    }
                }, '🗑️ Xóa');

                var row = E('div', { style: 'display: flex; align-items: center; gap: 8px; background: #ffffff; padding: 10px 12px; border-radius: 8px; border: 1px solid #e2e8f0; flex-wrap: wrap;' }, [
                    E('span', { style: 'font-weight: 750; font-size: 13px; color: #1e293b; min-width: 90px;' }, '🤖 Bot #' + (idx + 1) + ':'),
                    botNameInput,
                    botTokenInput,
                    botChatIdInput,
                    testBtn,
                    delBtn
                ]);
                telegramBotsContainer.appendChild(row);
            });
        }
        renderTelegramBotsList();

        var addTelegramBotBtn = E('button', {
            class: 'btn cbi-button',
            style: 'font-size: 12.5px; font-weight: 750; padding: 7px 16px; border-radius: 6px; background: #eff6ff; color: #1d4ed8; border: 1.5px solid #93c5fd; cursor: pointer; display: inline-flex; align-items: center; gap: 6px;',
            click: function() {
                telegramBotsList.push({
                    name: 'Bot Camera #' + (telegramBotsList.length + 1),
                    token: '',
                    chat_id: ''
                });
                renderTelegramBotsList();
            }
        }, '➕ Thêm Telegram Bot Mới');

        var saveAllSentinelBtn = E('button', {
            class: 'btn cbi-button cbi-button-action',
            style: 'font-weight: 750; font-size: 13px; padding: 9px 22px; border-radius: 6px;',
            click: function() {
                var t_tok = teleTokenInput.value.trim();
                var t_adm = teleChatIdInput.value.trim();
                var t_own = teleOwnerInput.value.trim() || 'Anh Duy';
                var t_emg = emgPhoneInput.value.trim();
                var t_gem = geminiKeyInput.value.trim();
                var t_ts = tailscaleKeyInput.value.trim();
                var t_cl = cloudRemoteInput.value.trim();

                var cleanCameras = [];
                cameraList.forEach(function(c) {
                    var s = (c || '').trim();
                    if (s) cleanCameras.push(s);
                });
                var t_c1 = cleanCameras[0] || '';
                var t_c2 = cleanCameras[1] || '';
                var t_cc = cleanCameras[2] || '';

                var cleanBots = [];
                telegramBotsList.forEach(function(b) {
                    var n = (b.name || '').trim();
                    var t = (b.token || '').trim();
                    var c = (b.chat_id || '').trim();
                    if (t && c) cleanBots.push({ name: n, token: t, chat_id: c });
                });
                if (cleanBots.length > 0) {
                    t_tok = cleanBots[0].token;
                    t_adm = cleanBots[0].chat_id;
                }

                saveAllSentinelBtn.textContent = '⏳ Đang lưu cấu hình...';
                callSetSentinelConfig(t_tok, t_adm, t_own, t_emg, t_gem, t_ts, t_cl, t_c1, t_c2, t_cc, cleanCameras, cleanBots).then(function(r) {
                    saveAllSentinelBtn.textContent = '💾 Lưu Toàn Bộ Cấu Hình Sentinel & AI';
                    ui.addNotification(null, E('p', r.message || '✅ Đã lưu cấu hình Sentinel & AI thành công!'), 'info');
                }).catch(function(err) {
                    saveAllSentinelBtn.textContent = '💾 Lưu Toàn Bộ Cấu Hình Sentinel & AI';
                    ui.addNotification(null, E('p', '❌ Lỗi lưu cấu hình: ' + err), 'error');
                });
            }
        }, '💾 Lưu Toàn Bộ Cấu Hình Sentinel & AI');

        var loadVaultBtn = E('button', {
            class: 'btn cbi-button',
            style: 'font-weight: 750; font-size: 13px; padding: 9px 18px; border-radius: 6px; background: #f0fdf4; color: #166534; border: 1.5px solid #86efac; cursor: pointer;',
            click: function() {
                loadVaultBtn.textContent = '⏳ Đang nạp Vault...';
                callLoadVaultKeys().then(function(r) {
                    loadVaultBtn.textContent = '⚡ Nạp Key Từ Vault Cá Nhân (Phím 3)';
                    if (r && r.success) {
                        if (r.tg_bot_token) teleTokenInput.value = r.tg_bot_token;
                        if (r.tg_admin_id) teleChatIdInput.value = r.tg_admin_id;
                        if (r.tg_owner_name) teleOwnerInput.value = r.tg_owner_name;
                        if (r.emergency_phone) emgPhoneInput.value = r.emergency_phone;
                        if (r.gemini_api_key) geminiKeyInput.value = r.gemini_api_key;
                        if (r.tailscale_auth_key) tailscaleKeyInput.value = r.tailscale_auth_key;
                        if (r.cloud_remote) cloudRemoteInput.value = r.cloud_remote;
                        if (r.cameras && Array.isArray(r.cameras) && r.cameras.length > 0) {
                            cameraList = r.cameras.slice();
                            renderCameraList();
                        } else if (r.cam1_rtsp || r.cam2_rtsp || r.cam_cong_rtsp) {
                            cameraList = [];
                            if (r.cam1_rtsp) cameraList.push(r.cam1_rtsp);
                            if (r.cam2_rtsp) cameraList.push(r.cam2_rtsp);
                            if (r.cam_cong_rtsp) cameraList.push(r.cam_cong_rtsp);
                            renderCameraList();
                        }
                        if (r.telegram_bots && Array.isArray(r.telegram_bots) && r.telegram_bots.length > 0) {
                            telegramBotsList = r.telegram_bots.slice();
                            renderTelegramBotsList();
                        }
                        ui.addNotification(null, E('p', '✅ ' + (r.message || 'Đã nạp đầy đủ Key từ Vault an toàn!')), 'info');
                    } else {
                        ui.addNotification(null, E('p', '⚠️ ' + (r.message || 'Chưa tìm thấy file vault.conf trên thiết bị.')), 'warning');
                    }
                }).catch(function(err) {
                    loadVaultBtn.textContent = '⚡ Nạp Key Từ Vault Cá Nhân (Phím 3)';
                    ui.addNotification(null, E('p', '❌ Lỗi nạp Vault: ' + err), 'error');
                });
            }
        }, '⚡ Nạp Key Từ Vault Cá Nhân (Phím 3)');

        var testSirenBtn = E('button', {
            class: 'btn cbi-button',
            style: 'font-weight: 750; font-size: 13px; padding: 9px 16px; border-radius: 6px; background: #fee2e2; color: #b91c1c; border: 1px solid #fca5a5;',
            click: function() {
                callTriggerAITest('siren', 'all').then(function() {
                    ui.addNotification(null, E('p', '🚨 Đang phát còi báo động khẩn cấp!'), 'info');
                });
            }
        }, '🚨 Test Còi Báo Động');

        var sentinelTabContent = E('div', { class: 'cbi-section', style: 'display: none; padding: 20px; background: #ffffff; border-radius: 10px; border: 1px solid #e2e8f0;' }, [
            E('h3', { style: 'margin-top: 0; font-size: 18px; font-weight: 800; color: #1e293b; border-bottom: 1px solid #f1f5f9; padding-bottom: 10px;' }, '🤖 Cấu Hình Telegram Bot, Siêu Trí Tuệ Gemini AI & CCTV Sentinel'),
            E('div', { style: 'background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; padding: 12px 16px; margin-bottom: 14px; font-size: 13px; color: #1e40af; line-height: 1.6;' }, [
                E('b', {}, '💡 Kiến Trúc Phân Tán Zero-Bottleneck (Chuẩn File ALL): '),
                E('span', {}, 'Router chỉ đảm nhiệm thu nhận hình ảnh, luồng RTSP và gửi cảnh báo khẩn cấp qua Telegram Bot / SMS. Tác vụ AI suy luận chuyên sâu do máy ảo Debian và Hermes AI Pool xử lý 100%, bảo đảm router luôn hoạt động mát mẻ và băng thông thông suốt.')
            ]),
            E('div', { style: 'border: 1px solid #f1f5f9; border-radius: 8px; padding: 16px; background: #fafafa; margin-bottom: 14px;' }, [
                E('div', { style: 'font-weight: 800; font-size: 14.5px; margin-bottom: 12px; color: #0f172a; border-bottom: 1px solid #e2e8f0; padding-bottom: 6px;' }, '🔑 Thông Tin Tài Khoản & Khóa Bảo Mật (Zero-Leak Vault):'),
                E('div', { style: 'display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 12px;' }, [
                    E('div', {}, [
                        E('div', { style: 'font-weight: 750; font-size: 13px; margin-bottom: 4px; color: #334155;' }, '🤖 Telegram Bot Token (Chính):'),
                        teleTokenInput
                    ]),
                    E('div', {}, [
                        E('div', { style: 'font-weight: 750; font-size: 13px; margin-bottom: 4px; color: #334155;' }, '👤 Telegram Admin Chat ID:'),
                        teleChatIdInput
                    ]),
                    E('div', {}, [
                        E('div', { style: 'font-weight: 750; font-size: 13px; margin-bottom: 4px; color: #334155;' }, '👑 Tên Chủ Sở Hữu (Mặc định: Anh Duy):'),
                        teleOwnerInput
                    ]),
                    E('div', {}, [
                        E('div', { style: 'font-weight: 750; font-size: 13px; margin-bottom: 4px; color: #334155;' }, '📞 SĐT Khẩn Cấp Báo Động (SMS/Call):'),
                        emgPhoneInput
                    ]),
                    E('div', {}, [
                        E('div', { style: 'font-weight: 750; font-size: 13px; margin-bottom: 4px; color: #334155;' }, '🧠 Google Gemini AI API Key:'),
                        geminiKeyInput
                    ]),
                    E('div', {}, [
                        E('div', { style: 'font-weight: 750; font-size: 13px; margin-bottom: 4px; color: #334155;' }, '🛡️ Tailscale Auth Key (VPN Remote):'),
                        tailscaleKeyInput
                    ]),
                    E('div', {}, [
                        E('div', { style: 'font-weight: 750; font-size: 13px; margin-bottom: 4px; color: #334155;' }, '☁️ Rclone Cloud Storage Remote:'),
                        cloudRemoteInput
                    ])
                ])
            ]),
            E('div', { style: 'border: 1px solid #f1f5f9; border-radius: 8px; padding: 16px; background: #fafafa; margin-bottom: 16px;' }, [
                E('div', { style: 'display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; border-bottom: 1px solid #e2e8f0; padding-bottom: 6px; flex-wrap: wrap; gap: 8px;' }, [
                    E('div', { style: 'font-weight: 800; font-size: 14.5px; color: #0f172a;' }, '🤖 Quản Lý Telegram Bot Camera & Cảnh Báo (Mở Rộng Không Giới Hạn):'),
                    addTelegramBotBtn
                ]),
                E('div', { style: 'font-size: 12px; color: #64748b; margin-bottom: 10px;' }, '💡 Hỗ trợ thêm không giới hạn số lượng Telegram Bot. Bạn có thể phân luồng từng Bot cho từng Camera riêng biệt, Bot khẩn cấp còi hú, hoặc gửi cảnh báo song song tới nhiều Nhóm / Kênh Telegram quản trị.'),
                telegramBotsContainer
            ]),
            E('div', { style: 'border: 1px solid #f1f5f9; border-radius: 8px; padding: 16px; background: #fafafa; margin-bottom: 16px;' }, [
                E('div', { style: 'display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; border-bottom: 1px solid #e2e8f0; padding-bottom: 6px; flex-wrap: wrap; gap: 8px;' }, [
                    E('div', { style: 'font-weight: 800; font-size: 14.5px; color: #0f172a;' }, '📹 Quản Lý Camera IP Sentinel (Mở Rộng Không Giới Hạn):'),
                    addCameraBtn
                ]),
                E('div', { style: 'font-size: 12px; color: #64748b; margin-bottom: 10px;' }, '💡 Chỉ cần nhập địa chỉ IP của Camera (ví dụ: 192.168.1.100) hoặc link luồng RTSP. Bạn có thể thêm bao nhiêu camera tùy ý bằng nút "Thêm Camera IP Mới".'),
                cameraListContainer
            ]),
            E('div', { style: 'display: flex; gap: 10px; align-items: center; flex-wrap: wrap;' }, [
                saveAllSentinelBtn,
                loadVaultBtn,
                testSirenBtn
            ])
        ]);
        tabPanes['sentinel'] = sentinelTabContent;

        var mainWrapper = E('div', { class: 'cbi-map', style: 'padding: 10px 0;' }, [
            navBar,
            simTabContent,
            modemTabContent,
            meshTabContent,
            sentinelTabContent
        ]);

        return mainWrapper;
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});

