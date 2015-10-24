m = Map("cgminer", translate("Configuration"),
        translate("Please visit <a href='https://ehash.com/support'> https://ehash.com/support</a> for support,"..
        "visit <a href='http://downloads.canaan-creative.com'> http://downloads.canaan-creative.com</a> for firmware download."))

conf = m:section(TypedSection, "cgminer", "")
conf.anonymous = true
conf.addremove = false

ntp = conf:option(ListValue, "ntp_enable", translate("NTP Service(Default: Disable)"))
ntp.default = "disable"
ntp:value("asia", translate("ASIA"))
ntp:value("openwrt", translate("OpenWrt Default"))
ntp:value("disable", translate("Disable"))

pool1url = conf:option(Value, "pool1url", translate("Pool 1"))
pool1user = conf:option(Value, "pool1user", translate("Pool1 worker"))
pool1pw = conf:option(Value, "pool1pw", translate("Pool1 password"))
pool2url = conf:option(Value, "pool2url", translate("Pool 2"))
pool2user = conf:option(Value, "pool2user", translate("Pool2 worker"))
pool2pw = conf:option(Value, "pool2pw", translate("Pool2 password"))
pool3url = conf:option(Value, "pool3url", translate("Pool 3"))
pool3user = conf:option(Value, "pool3user", translate("Pool3 worker"))
pool3pw = conf:option(Value, "pool3pw", translate("Pool3 password"))

cf = conf:option(Value, "chip_frequency", translate("Chip Frequency(Default: 500)"))
cf.default = "450:390:370"

fan = conf:option(Value, "fan", translate("Fan%(Default: 20%)"))
fan.datatype = "range(0, 100)"

api_allow = conf:option(Value, "api_allow", translate("API Allow(Default: W:127.0.0.1)"))
more_options = conf:option(Value, "more_options", translate("More Options(Default: --real-quiet)"))

return m
