'use strict';
'require form';
'require network';

return network.registerProtocol('duydoan5g', {
	getI18n: function() {
		return _('DuyDoan 5G/LTE Cellular (PCIe/USB)');
	},

	getIfname: function() {
		return this._ubus('l3_device') || 'mhi_hwip0';
	},

	isFloating: function() {
		return true;
	},

	isVirtual: function() {
		return true;
	},

	getDevices: function() {
		return null;
	},

	containsDevice: function(ifname) {
		return (network.getIfnameOf(ifname) == this.getIfname());
	},

	renderFormOptions: function(s) {
		var o;

		o = s.taboption('general', form.ListValue, 'apn_preset', _('Nhà mạng (APN)'));
		o.value('v-internet', 'Viettel Telecom (v-internet)');
		o.value('m3-world', 'VNPT Vinaphone / Wintel (m3-world)');
		o.value('m-i090', 'MobiFone (m-i090)');
		o.value('custom', _('Tùy chỉnh APN...'));
		o.default = 'v-internet';

		o = s.taboption('general', form.Value, 'apn', _('Tên APN tùy chỉnh'));
		o.default = 'v-internet';
		o.depends('apn_preset', 'custom');

		o = s.taboption('general', form.ListValue, 'pdp', _('Giao thức PDP'));
		o.value('ipv4v6', 'IPv4 / IPv6 (Dual Stack)');
		o.value('ipv4', 'Chỉ IPv4');
		o.value('ipv6', 'Chỉ IPv6');
		o.default = 'ipv4v6';

		o = s.taboption('advanced', form.Value, 'metric', _('Độ ưu tiên Metric (Mặc định 10)'));
		o.default = '10';
		o.datatype = 'uinteger';

		o = s.taboption('advanced', form.Value, 'pincode', _('Mã PIN thẻ SIM'));
		o.datatype = 'uinteger';
	}
});
