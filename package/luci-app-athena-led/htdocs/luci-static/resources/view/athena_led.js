// [VERIFIED-GOLDEN: luci-view-athena-led-pro-vi | 2026-11-27 | DO NOT MODIFY UNLESS TARGETED]
'use strict';
'require dom';
'require form';
'require poll';
'require rpc';
'require ui';
'require view';

var callAthenaStatus = rpc.declare({
	object: 'luci.athena_led',
	method: 'getStatus',
	expect: { '': {} }
});

var callCycleBrightness = rpc.declare({
	object: 'luci.athena_led',
	method: 'cycleBrightness',
	expect: { '': {} }
});

var callRefreshLive = rpc.declare({
	object: 'luci.athena_led',
	method: 'refreshLive',
	expect: { '': {} }
});

function addChoices(option, choices) {
	for (var i = 0; i < choices.length; i++)
		option.value(choices[i][0], choices[i][1]);
	return option;
}

function toStringList(value) {
	var values = L.toArray(value);
	var list = [];
	for (var i = 0; i < values.length; i++) {
		var item = values[i];
		if (item == null)
			continue;
		if (typeof(item) == 'string') {
			item = item.trim();
			if (item == '')
				continue;
			list = list.concat(item.split(/\s+/));
		} else {
			list.push(String(item));
		}
	}
	return list;
}

var SpaceSeparatedCheckboxValue = form.MultiValue.extend({
	renderWidget: function(section_id, option_index, cfgvalue) {
		var choices = this.transformChoices();
		var widget = new ui.Select(toStringList((cfgvalue != null) ? cfgvalue : this.default), choices, {
			id: this.cbid(section_id),
			sort: this.keylist,
			multiple: true,
			widget: 'checkbox',
			orientation: this.orientation || 'horizontal',
			disabled: (this.readonly != null) ? this.readonly : this.map.readonly
		});
		var node = widget.render();
		var inputs = node.querySelectorAll('input[type="checkbox"]');
		var items = node.querySelectorAll('.cbi-checkbox');

		node.style.setProperty('display', 'inline-flex', 'important');
		Object.assign(node.style, {
			flexWrap: 'wrap',
			alignItems: 'center',
			columnGap: '1em',
			rowGap: '.4em'
		});

		for (var i = node.childNodes.length - 1; i >= 0; i--)
			if (node.childNodes[i].nodeType == 3)
				node.removeChild(node.childNodes[i]);

		for (var i = 0; i < items.length; i++) {
			items[i].style.setProperty('display', 'inline-flex', 'important');
			Object.assign(items[i].style, {
				alignItems: 'center',
				whiteSpace: 'nowrap'
			});
		}

		widget.getValue = function() {
			var values = [];
			for (var i = 0; i < inputs.length; i++)
				if (inputs[i].checked)
					values.push(inputs[i].value);
			return values;
		};

		widget.setValue = function(value) {
			var values = toStringList(value);
			for (var i = 0; i < inputs.length; i++)
				inputs[i].checked = (values.indexOf(inputs[i].value) > -1);
		};

		for (var i = 0; i < inputs.length; i++) {
			widget.setUpdateEvents(inputs[i], 'change', 'click', 'blur');
			widget.setChangeEvents(inputs[i], 'change');
		}

		return node;
	},

	cfgvalue: function(section_id, set_value) {
		if (arguments.length == 2)
			return this.super('cfgvalue', [ section_id, set_value ]);
		return toStringList(this.super('cfgvalue', [ section_id ]));
	},

	write: function(section_id, value) {
		return this.super('write', [ section_id, toStringList(value).join(' ') ]);
	}
});

function stateLabelVi(state, running) {
	if (!running)
		return 'Đang tắt dịch vụ';
	if (state === 'DIM')
		return 'Sáng dịu (Mức 1)';
	if (state === 'OFF')
		return 'Tạm tắt màn hình (Bấm nút Screen để bật lại)';
	return 'Sáng chuẩn';
}

function renderStatusCard(info) {
	var running = !!(info && info.running);
	var supported = !!(info && info.supported);
	var model = (info && info.model) ? info.model : 'Router';
	var bState = stateLabelVi(info && info.brightness_state, running);

	var badgeStyle = running
		? 'background:#dcfce7;color:#15803d;padding:4px 10px;border-radius:999px;font-weight:700;font-size:12.5px;'
		: 'background:#fee2e2;color:#b91c1c;padding:4px 10px;border-radius:999px;font-weight:700;font-size:12.5px;';

	var details = [
		E('div', { 'style': 'display:flex;flex-wrap:wrap;align-items:center;gap:10px;justify-content:space-between;' }, [
			E('div', { 'style': 'display:flex;align-items:center;gap:10px;flex-wrap:wrap;' }, [
				E('span', { 'style': badgeStyle }, [ running ? '● ĐANG HOẠT ĐỘNG' : '○ ĐANG TẮT' ]),
				E('strong', { 'style': 'font-size:14px;' }, [ model ]),
				E('span', { 'style': 'color:#475569;font-size:13px;' }, [ '• Chế độ sáng: ' + bState ])
			]),
			E('div', { 'style': 'display:flex;gap:8px;flex-wrap:wrap;' }, [
				E('button', {
					'class': 'btn cbi-button cbi-button-action',
					'click': ui.createHandlerFn(this, function() {
						return callCycleBrightness().then(function() {
							ui.addNotification(null, E('p', 'Đã chuyển nhanh mức sáng màn hình LED!'), 'info');
						});
					})
				}, [ 'Đổi Mức Sáng Nhanh (Nút Screen)' ]),
				E('button', {
					'class': 'btn cbi-button cbi-button-neutral',
					'click': ui.createHandlerFn(this, function() {
						return callRefreshLive().then(function() {
							ui.addNotification(null, E('p', 'Đã cập nhật dữ liệu Thời tiết & 5G mới nhất!'), 'info');
						});
					})
				}, [ 'Cập Nhật Thời Tiết & 5G Ngay' ])
			])
		])
	];

	if (!supported) {
		details.push(E('div', {
			'style': 'margin-top:8px;padding:8px 12px;border-radius:8px;background:#fef3c7;color:#92400e;font-size:12.5px;'
		}, [ 'Thiết bị hiện tại (' + model + ') không phải bo mạch JDCloud RE-CS-02 nên dịch vụ tự động nghỉ an toàn (0% CPU, không chạm GPIO).' ]));
	} else if (info && (info.live_modem5g || info.live_weather)) {
		var liveParts = [];
		if (info.live_modem5g) liveParts.push('5G/Data: ' + info.live_modem5g);
		if (info.live_weather) liveParts.push('Thời tiết: ' + info.live_weather);
		details.push(E('div', {
			'style': 'margin-top:8px;font-size:12.5px;color:#334155;'
		}, [ 'Dữ liệu trực tiếp: ' + liveParts.join('  •  ') ]));
	}

	return E('div', {
		'style': 'padding:14px 16px;border:1px solid #cbd5e1;border-radius:10px;background:#f8fafc;margin-bottom:8px;'
	}, details);
}

return view.extend({
	load: function() {
		return L.resolveDefault(callAthenaStatus(), {});
	},

	render: function(initialStatus) {
		var m, s, o;
		var statusBox = E('div', { 'id': 'athena-led-pro-status' }, [ renderStatusCard(initialStatus) ]);

		poll.add(function() {
			return L.resolveDefault(callAthenaStatus(), {}).then(function(res) {
				dom.content(statusBox, renderStatusCard(res));
			});
		}, 3);

		m = new form.Map('athena_led',
			'Màn Hình LED Ma Trận & Đèn RGB — JDCloud Athena (RE-CS-02)',
			'Điều khiển màn hình LED ma trận 27×5, icon tốc độ mạng động, sóng 5G, Âm lịch Việt Nam, dải đèn RGB mặt trước và nút cứng Screen trên thân máy.');

		s = m.section(form.TypedSection);
		s.anonymous = true;
		s.render = function() { return statusBox; };

		s = m.section(form.NamedSection, 'config', 'athena_led', 'Cấu Hình Hiển Thị & Đèn Trạng Thái');
		s.anonymous = true;
		s.addremove = false;

		s.tab('display', 'Màn Hình Ma Trận LED');
		s.tab('rgb_night', 'Đèn Dải RGB & Chế Độ Ban Đêm');

		/* === TAB 1: MATRIX DISPLAY === */
		o = s.taboption('display', form.Flag, 'enable', 'Bật màn hình LED Athena',
			'Tự động chạy trên JDCloud RE-CS-02. Bạn cũng có thể bấm nhanh nút cứng Screen trên thân router để đổi độ sáng/tắt nhanh.');
		o.default = '1';
		o.rmempty = false;

		o = s.taboption('display', form.ListValue, 'lightLevel', 'Độ sáng màn hình (0 - 7)',
			'Mức 0 là dịu nhất, mức 7 là sáng tối đa (khuyên dùng mức 4 hoặc 5).');
		o.default = '5';
		o.rmempty = false;
		for (var lv = 0; lv <= 7; lv++)
			o.value(String(lv), 'Mức ' + lv + (lv === 0 ? ' (Rất dịu)' : (lv === 5 ? ' (Khuyên dùng)' : (lv === 7 ? ' (Sáng nhất)' : ''))));

		o = s.taboption('display', form.ListValue, 'seconds', 'Thời gian chuyển trang (Giây)',
			'Thời gian giữ mỗi nội dung trước khi chuyển sang mục tiếp theo.');
		o.default = '5';
		o.rmempty = false;
		addChoices(o, [
			[ '2', '2 giây' ],
			[ '3', '3 giây' ],
			[ '5', '5 giây (Khuyên dùng)' ],
			[ '8', '8 giây' ],
			[ '10', '10 giây' ],
			[ '15', '15 giây' ]
		]);

		o = s.taboption('display', SpaceSeparatedCheckboxValue, 'option', 'Nội dung xoay vòng trên màn hình',
			'Chọn một hoặc nhiều chế độ để hiển thị lần lượt.');
		o.default = 'timeBlink date lunar netSpeed string';
		o.rmempty = false;
		o.required = true;
		addChoices(o, [
			[ 'timeBlink', 'Giờ hiện tại (Nhấp nháy :)' ],
			[ 'time', 'Giờ hiện tại (Tĩnh)' ],
			[ 'date', 'Ngày Dương lịch (DD-MM)' ],
			[ 'lunar', 'Ngày Âm lịch Việt Nam (Offline)' ],
			[ 'netSpeed', 'Tốc độ mạng thực tế (KB/s - MB/s)' ],
			[ 'modem5g', 'Sóng 5G & Dung lượng Data' ],
			[ 'meshInfo', 'Vai trò Auto-Mesh & Số thiết bị' ],
			[ 'weatherVN', 'Thời tiết & Tỷ lệ mưa Việt Nam' ],
			[ 'temp', 'Nhiệt độ CPU / Phần cứng' ],
			[ 'string', 'Chữ chạy tùy chỉnh' ],
			[ 'getByUrl', 'Đọc nội dung từ URL / File' ]
		]);

		o = s.taboption('display', form.Flag, 'autoIcons', 'Tự động nháy 4 icon cạnh bên (🕒 🏅 ⬆️ ⬇️)',
			'Tự sáng đồng hồ khi hiện giờ/ngày, sáng huy chương khi có mạng/Mesh, và nháy mũi tên Lên/Xuống khi có lưu lượng tải thực tế.');
		o.default = '1';
		o.rmempty = false;

		o = s.taboption('display', SpaceSeparatedCheckboxValue, 'status', 'Cố định thêm icon cạnh bên (Tùy chọn)',
			'Luôn giữ sáng các icon được tích chọn bên dưới bất kể lưu lượng.');
		o.rmempty = true;
		addChoices(o, [
			[ 'time', 'Đồng hồ (Time)' ],
			[ 'medal', 'Huy chương (Medal)' ],
			[ 'upload', 'Mũi tên Tải lên (Upload)' ],
			[ 'download', 'Mũi tên Tải xuống (Download)' ]
		]);

		o = s.taboption('display', form.Value, 'value', 'Nội dung chữ tùy chỉnh',
			'Hiển thị khi tích chọn chế độ "Chữ chạy tùy chỉnh" (tự động chuyển tiếng Việt có dấu sang chữ in hoa sắc nét).');
		o.default = 'DOAN DUY';
		o.placeholder = 'Ví dụ: DOAN DUY 5G';
		o.rmempty = false;
		o.retain = true;
		o.depends({ option: 'string', '!contains': true });

		o = s.taboption('display', form.ListValue, 'city', 'Tỉnh / Thành phố dự báo thời tiết',
			'Áp dụng khi bật chế độ "Thời tiết & Tỷ lệ mưa Việt Nam".');
		o.default = 'HoChiMinh';
		o.rmempty = false;
		o.retain = true;
		o.depends({ option: 'weatherVN', '!contains': true });
		addChoices(o, [
			[ 'HoChiMinh', 'TP. Hồ Chí Minh' ],
			[ 'HaNoi', 'Thủ đô Hà Nội' ],
			[ 'DaNang', 'TP. Đà Nẵng' ],
			[ 'CanTho', 'TP. Cần Thơ' ],
			[ 'HaiPhong', 'TP. Hải Phòng' ],
			[ 'NhaTrang', 'Nha Trang - Khánh Hòa' ],
			[ 'DaLat', 'Đà Lạt - Lâm Đồng' ],
			[ 'Hue', 'Cố đô Huế' ],
			[ 'VungTau', 'Vũng Tàu' ]
		]);

		o = s.taboption('display', SpaceSeparatedCheckboxValue, 'tempFlag', 'Cảm biến nhiệt độ cần xem',
			'Áp dụng khi bật chế độ "Nhiệt độ CPU / Phần cứng".');
		o.default = '4';
		o.rmempty = false;
		o.retain = true;
		o.depends({ option: 'temp', '!contains': true });
		addChoices(o, [
			[ '4', 'CPU trung tâm' ],
			[ '1', 'Chip tăng tốc NSS' ],
			[ '0', 'NSS-TOP' ],
			[ '2', 'Wi-Fi PHYA0' ],
			[ '3', 'Wi-Fi PHYA1' ],
			[ '6', 'RAM DDRSS' ]
		]);

		o = s.taboption('display', form.Value, 'url', 'Đường dẫn URL hoặc File nội bộ',
			'Hỗ trợ http(s)://... hoặc đường dẫn file nội bộ như /tmp/weather.txt (timeout an toàn 4 giây, không gây đơ đồng hồ).');
		o.default = '';
		o.placeholder = 'Ví dụ: /tmp/weather.txt hoặc https://ifconfig.me';
		o.rmempty = true;
		o.retain = true;
		o.depends({ option: 'getByUrl', '!contains': true });

		/* === TAB 2: FRONT RGB BAR & NIGHT SCHEDULE === */
		o = s.taboption('rgb_night', form.ListValue, 'rgbMode', 'Chế độ dải đèn LED RGB mặt trước',
			'Đồng bộ dải đèn trạng thái mặt trước theo kết nối mạng & Auto-Mesh.');
		o.default = 'auto';
		o.rmempty = false;
		addChoices(o, [
			[ 'auto', 'Tự động thông minh (Có mạng: Xanh lá/Ngọc • Dò Mesh: Nháy Xanh dương • Mất mạng: Đỏ)' ],
			[ 'green', 'Luôn sáng Xanh lá' ],
			[ 'cyan', 'Luôn sáng Xanh băng (Cyan)' ],
			[ 'blue', 'Luôn sáng Xanh dương' ],
			[ 'purple', 'Luôn sáng Tím (Purple)' ],
			[ 'white', 'Luôn sáng Trắng' ],
			[ 'red', 'Luôn sáng Đỏ' ],
			[ 'off', 'Tắt hẳn dải đèn RGB mặt trước' ],
			[ 'system', 'Mặc định OpenWrt (Không can thiệp)' ]
		]);

		o = s.taboption('rgb_night', form.Flag, 'nightMode', 'Bật hẹn giờ Ban Đêm (Ngủ ngon không chói mắt)',
			'Tự động tắt hoặc hạ độ sáng màn hình LED + tắt đèn RGB trong khung giờ nghỉ ngơi.');
		o.default = '0';
		o.rmempty = false;

		o = s.taboption('rgb_night', form.Value, 'nightStart', 'Giờ bắt đầu Ban Đêm (HH:MM)');
		o.default = '23:00';
		o.placeholder = '23:00';
		o.rmempty = false;
		o.retain = true;
		o.depends('nightMode', '1');

		o = s.taboption('rgb_night', form.Value, 'nightEnd', 'Giờ bật sáng trở lại (HH:MM)');
		o.default = '06:00';
		o.placeholder = '06:00';
		o.rmempty = false;
		o.retain = true;
		o.depends('nightMode', '1');

		o = s.taboption('rgb_night', form.ListValue, 'nightLevel', 'Mức hiển thị trong giờ Ban Đêm');
		o.default = '-1';
		o.rmempty = false;
		o.retain = true;
		o.depends('nightMode', '1');
		addChoices(o, [
			[ '-1', 'Tắt hoàn toàn cả màn hình LED & dải RGB (Khuyên dùng phòng ngủ)' ],
			[ '0', 'Giảm màn hình về mức siêu dịu (Mức 0) & giữ nhẹ' ],
			[ '1', 'Giảm màn hình về mức dịu nhẹ (Mức 1)' ]
		]);

		return m.render();
	}
});
// [/VERIFIED-GOLDEN]
