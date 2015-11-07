m = Map("cgminer", translate("Configuration"))

ntp_section = m:section(TypedSection, "cgminer", translate("NTP"))
ntp_section.template = "cgsetting/cbi_tblsection"
ntp_section.anonymous = true
ntp_section.addremove = false

ntp = ntp_section:option(ListValue, "ntp_enable", translate("NTP Service(Default: Disable)"))
ntp.default = "disable"
ntp:value("asia", translate("ASIA"))
ntp:value("openwrt", translate("OpenWrt Default"))
ntp:value("disable", translate("Disable"))

pool1section = m:section(TypedSection, "cgminer", translate("Pool1"))
pool1section.template = "cgsetting/cbi_tblsection"
pool1section.anonymous = true
pool1url = pool1section:option(Value, "pool1url", translate("Pool 1 url"))
pool1user = pool1section:option(Value, "pool1user", translate("Pool1 worker"))
pool1pw = pool1section:option(Value, "pool1pw", translate("Pool1 password"))

pool2section = m:section(TypedSection, "cgminer", translate("Pool2"))
pool2section.template = "cgsetting/cbi_tblsection"
pool2section.anonymous = true
pool2url = pool2section:option(Value, "pool2url", translate("Pool 2 url"))
pool2user = pool2section:option(Value, "pool2user", translate("Pool2 worker"))
pool2pw = pool2section:option(Value, "pool2pw", translate("Pool2 password"))

pool3section = m:section(TypedSection, "cgminer", translate("Pool3"))
pool3section.template = "cgsetting/cbi_tblsection"
pool3section.anonymous = true
pool3url = pool3section:option(Value, "pool3url", translate("Pool 3 url"))
pool3user = pool3section:option(Value, "pool3user", translate("Pool3 worker"))
pool3pw = pool3section:option(Value, "pool3pw", translate("Pool3 password"))

--machinesection = m:section(TypeSection, "cgminer", translate("Machine"))
--machinesection.template = "cgsetting/cbi_tblsection"
--machinesection.anonymous = true
--chip_frequency = machinesection:option(Value, "chip_frequency", translate("Chip Frequency(Avalon2: 1500, Avalon3: 450)"))
--chip_voltage = machinesection:option(Value, "chip_voltage", translate("Chip Voltage(Avalon2: 10000, Avalon3: 6625)"))
--fan = machinesection:option(Value, "fan", translate("Fan%(Default: 90%)"))

-- etcsection = m:section(TypeSection, "cgminer", "")
-- etcsection.template = "cgsetting/cbi_tblsection"
-- etcsection.anonymous = true
-- api_allow = etcsection:option(Value, "api_allow", translate("API Allow(Default: W:127.0.0.1)"))
-- more_options = etcsection:option(Value, "more_options", translate("More Options(Default: --quiet)"))

return m
