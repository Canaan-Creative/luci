m = Map("cgminer", "Configuration", "")

conf = m:section(TypedSection, "cgminer", "")
conf.anonymous = true
conf.addremove = false

conf:tab("default", translate("General Settings"))

pool1url = conf:taboption("default", Value, "pool1url", translate("Pool 1"))
pool1user = conf:taboption("default", Value, "pool1user", translate("Pool1 worker"))
pool1pw = conf:taboption("default", Value, "pool1pw", translate("Pool1 password"))
pool2url = conf:taboption("default", Value, "pool2url", translate("Pool 2"))
pool2user = conf:taboption("default", Value, "pool2user", translate("Pool2 worker"))
pool2pw = conf:taboption("default", Value, "pool2pw", translate("Pool2 password"))
pool3url = conf:taboption("default", Value, "pool3url", translate("Pool 3"))
pool3user = conf:taboption("default", Value, "pool3user", translate("Pool3 worker"))
pool3pw = conf:taboption("default", Value, "pool3pw", translate("Pool3 password"))

return m
