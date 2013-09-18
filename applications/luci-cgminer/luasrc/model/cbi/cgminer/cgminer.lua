m = Map("cgminer", translate("Configuration"),
        translate("Please visit <a href='http://en.bitcoin.it/wiki/Avalon'> http://en.bitcoin.it/wiki/Avalon</a> for documentation and "..
        "join IRC channel: <a href='http://goo.gl/2ll1C0'> #avalon @freenode.net</a> for share and help."))

conf = m:section(TypedSection, "cgminer", "")
conf.anonymous = true
conf.addremove = false

pool1url = conf:option(Value, "pool1url", translate("Pool 1"))
pool1user = conf:option(Value, "pool1user", translate("Pool1 worker"))
pool1pw = conf:option(Value, "pool1pw", translate("Pool1 password"))
pool2url = conf:option(Value, "pool2url", translate("Pool 2"))
pool2user = conf:option(Value, "pool2user", translate("Pool2 worker"))
pool2pw = conf:option(Value, "pool2pw", translate("Pool2 password"))
pool3url = conf:option(Value, "pool3url", translate("Pool 3"))
pool3user = conf:option(Value, "pool3user", translate("Pool3 worker"))
pool3pw = conf:option(Value, "pool3pw", translate("Pool3 password"))

pb = conf:option(ListValue, "pool_balance", translate("Pool Balance(Default: Balance)"))
pb.default = "--balance"
pb:value("--balance", translate("Balance"))
pb:value("--load-balance", translate("Load Balance"))
pb:value("  ", translate("Failover"))

cf = conf:option(Value, "chip_frequency", translate("Chip Frequency(Default: 300)"))

mc = conf:option(Value, "miner_count", translate("Miner Count(Default: 24)"))
api_allow = conf:option(Value, "api_allow", translate("API Allow(Default: W:127.0.0.1)"))

target=conf:option(Value, "target", translate("Target Temperature"))
overheat=conf:option(Value, "overheat", translate("Overheat Cut Off Temperature"))

more_options = conf:option(Value, "more_options", translate("More Options(Default: --quiet)"))

return m
