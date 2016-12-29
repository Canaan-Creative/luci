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
pool1url.datatype = "string"
pool1url:value("stratum+tcp://stratum.kano.is:3333")
pool1url:value("stratum+tcp://stratum.haobtc.com:3333")
pool1user = pool1section:option(Value, "pool1user", translate("Pool1 worker"))
pool1pw = pool1section:option(Value, "pool1pw", translate("Pool1 password"))

pool2section = m:section(TypedSection, "cgminer", translate("Pool2"))
pool2section.template = "cgsetting/cbi_tblsection"
pool2section.anonymous = true
pool2url = pool2section:option(Value, "pool2url", translate("Pool 2 url"))
pool2url.datatype = "string"
pool2url:value("stratum+tcp://stratum80.kano.is:80")
pool2url:value("stratum+tcp://stratum.haobtc.com:443")
pool2user = pool2section:option(Value, "pool2user", translate("Pool2 worker"))
pool2pw = pool2section:option(Value, "pool2pw", translate("Pool2 password"))

pool3section = m:section(TypedSection, "cgminer", translate("Pool3"))
pool3section.template = "cgsetting/cbi_tblsection"
pool3section.anonymous = true
pool3url = pool3section:option(Value, "pool3url", translate("Pool 3 url"))
pool3url.datatype = "string"
pool3url:value("stratum+tcp://stratum80.kano.is:81")
pool3url:value("stratum+tcp://stratum.haobtc.com:25")
pool3user = pool3section:option(Value, "pool3user", translate("Pool3 worker"))
pool3pw = pool3section:option(Value, "pool3pw", translate("Pool3 password"))

return m
