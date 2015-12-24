m = Map("cgminer", translate("Pool Status"),
	translate("Read pool status from pool's api"))
s = m:section(TypedSection, "cgminer")
s.addremove = false
s.anonymous = true
function s:filter(value)
    return value =="pool" and value
end

poolkey = s:option(Value, "btcchina_poolkey", "BTCchina Poolkey")
poolkey = s:option(Value, "btcchina_worker", "BTCchina Worker")
poolkey = s:option(Value, "kanois_poolkey", "kano.is Poolkey")
poolkey = s:option(Value, "kanois_worker", "kano.is Worker")

return m
