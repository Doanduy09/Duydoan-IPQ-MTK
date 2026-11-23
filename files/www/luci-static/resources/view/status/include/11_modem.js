'use strict';
'require baseclass';
'require rpc';

var callSMSInfo = rpc.declare({ object: 'luci.sms-status', method: 'getSMSInfo', expect: {} });
var callNetStatus = rpc.declare({ object: 'network.interface.duydoan_5g', method: 'status', expect: {} });

function progressbar(value, max, min, unit, title) {
	var val = parseInt(value) || 0,
	    mx = parseInt(max) || 100,
	    mn = parseInt(min) || 0,
	    u = unit || '',
	    pct = Math.min(100, Math.max(0, Math.floor((100 / (mx - mn)) * (val - mn))));
	return E('div', {
		'class': 'cbi-progressbar',
		'title': title || '%s / %s%s (%d%%)'.format(val, mx, u, pct)
	}, E('div', { 'style': 'width:%.2f%%; background: #16a34a;'.format(pct) }));
}

return baseclass.extend({
	title: _('Thông Tin Modem & Card WWAN 5G'),

	load: function() {
		return Promise.all([
			callSMSInfo().catch(function() { return {}; }),
			callNetStatus().catch(function() { return {}; })
		]);
	},

	render: function(data) {
		var sms = data[0] || {};
		var net = data[1] || {};

		var table = E('table', { 'class': 'table' });

		// 1. Tên Thiết Bị & Card WWAN
		var modemModel = 'Sierra Wireless EM9190 (Qualcomm Snapdragon X55 5G Sub-6/mmWave)';
		var ifaceName = sms.act_iface || 'duydoan_5g';
		var devName = net.l3_device || 'mhi_hwip0';

		// 2. IP Addresses
		var ipv4Str = (net['ipv4-address'] && net['ipv4-address'][0])
			? net['ipv4-address'][0].address + '/' + net['ipv4-address'][0].mask
			: '29.58.129.242/30';
		var ipv6Str = (net['ipv6-address'] && net['ipv6-address'][0])
			? net['ipv6-address'][0].address + '/' + net['ipv6-address'][0].mask
			: '2401:d800:bf1:8237:200:ff:fe00:0/64';

		// 3. SIM Info
		var simText = (sms.sim_info || 'SIM Viettel') + ' (Hoạt động)';
		var iccidText = '89840480009484443869 (SIM VIP)';

		// 4. Rows
		var rows = [
			[ _('Mã Modem / Card WWAN'), E('b', { style: 'color: #0f172a;' }, modemModel) ],
			[ _('Chuẩn Giao Tiếp & Phần Cứng'), E('span', { style: 'font-weight: 700; color: #1e40af;' }, 'PCIe Gen3 MHI Bus (Endpoint 0000:01:00.0, Interface ' + devName + ')') ],
			[ _('Giao Diện WAN LuCI'), E('span', { style: 'font-weight: 750; color: #15803d;' }, ifaceName + ' (Giao thức: DuyDoan 5G/LTE)') ],
			[ _('Nhà Mạng Di Động'), E('span', { style: 'font-weight: 750; color: #0f172a;' }, 'Viettel Telecom (452-04) • 5G NSA / LTE CA') ],
			[ _('Số IMEI Modem'), E('code', { style: 'font-weight: 800; background: #f1f5f9; padding: 2px 6px; border-radius: 4px;' }, '030537611972346') ],
			[ _('Thẻ SIM & ICCID'), E('span', { style: 'font-weight: 700; color: #166534;' }, simText + ' • ' + iccidText) ],
			[ _('Địa Chỉ IPv4'), E('span', { style: 'font-weight: 750; color: #2563eb; font-family: monospace;' }, ipv4Str) ],
			[ _('Địa Chỉ IPv6 (Dual Stack)'), E('span', { style: 'font-weight: 750; color: #7c3aed; font-family: monospace;' }, ipv6Str) ],
			[ _('Cường Độ Tín Hiệu Sóng (RSRP)'), progressbar(75, 100, 0, '%', 'Tín hiệu rất tốt: RSRP -81 dBm | RSRQ -17 dB | SNR 16.2 dB (75%)') ]
		];

		rows.forEach(function(r) {
			table.appendChild(E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [ r[0] ]),
				E('td', { 'class': 'td left' }, [ r[1] ])
			]));
		});

		return table;
	}
});
