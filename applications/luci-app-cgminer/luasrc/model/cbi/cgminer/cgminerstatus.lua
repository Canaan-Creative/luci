--[[
LuCI - Lua Configuration Interface

Copyright 2014 Fengling <Fengling.Qin@gmail.com>
Copyright 2013 Xiangfu
Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--
btnref = luci.dispatcher.build_url("admin", "status", "cgminerstatus", "restart")
f = SimpleForm("cgminerstatus", translate("Cgminer Status") ..
		    "  <input type=\"button\" value=\" " .. translate("Restart Cgminer") .. " \" onclick=\"location.href='" .. btnref .. "'\" href=\"#\"/>",
		    translate("Please visit <a href='https://ehash.com/support'> https://ehash.com/support</a> for support,"..
		    "visit <a href='http://downloads.canaan-creative.com'>http://downloads.canaan-creative.com</a> for firmware download."))

f.reset = false
f.submit = false

t = f:section(Table, luci.controller.cgminer.summary(), translate("Summary"))
t:option(DummyValue, "elapsed", translate("Elapsed"))
ghsav = t:option(DummyValue, "mhsav", translate("GHSav"))
function ghsav.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section):gsub(",","")
	return string.format("%.2f", tonumber(v)/1000)
end

t:option(DummyValue, "accepted", translate("Accepted"))
t:option(DummyValue, "rejected", translate("Rejected"))
t:option(DummyValue, "networkblocks", translate("NetworkBlocks"))
t:option(DummyValue, "bestshare", translate("BestShare"))

t2 = f:section(Table, luci.controller.cgminer.pools(), translate("Pools"))
t2:option(DummyValue, "pool", translate("Pool"))
t2:option(DummyValue, "url", translate("URL"))
t2:option(DummyValue, "stratumactive", translate("StratumActive"))
t2:option(DummyValue, "user", translate("User"))
t2:option(DummyValue, "status", translate("Status"))
t2:option(DummyValue, "stratumdifficulty", translate("StratumDifficulty"))
t2:option(DummyValue, "getworks", translate("GetWorks"))
t2:option(DummyValue, "accepted", translate("Accepted"))
t2:option(DummyValue, "rejected", translate("Rejected"))
t2:option(DummyValue, "stale", translate("Stale"))
t2:option(DummyValue, "lastsharetime", translate("LST"))
t2:option(DummyValue, "lastsharedifficulty", translate("LSD"))

t1 = f:section(Table, luci.controller.cgminer.devs(), translate("Avalon Devices"))
t1:option(DummyValue, "name", translate("Device"))
t1:option(DummyValue, "enable", translate("Enabled"))
t1:option(DummyValue, "status", translate("Status"))
t1:option(DummyValue, "temp", translate("Temperature(C)"))
ghsav = t1:option(DummyValue, "mhsav", translate("GHSav"))
function ghsav.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	return string.format("%.2f", v/1000)
end

ghs5s = t1:option(DummyValue, "mhs5s", translate("GHS5s"))
function ghs5s.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	return string.format("%.2f", v/1000)
end

ghs1m = t1:option(DummyValue, "mhs1m", translate("GHS1m"))
function ghs1m.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	return string.format("%.2f", v/1000)
end

ghs5m = t1:option(DummyValue, "mhs5m", translate("GHS5m"))
function ghs5m.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	return string.format("%.2f", v/1000)
end

ghs15m = t1:option(DummyValue, "mhs15m", translate("GHS15m"))
function ghs15m.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	return string.format("%.2f", v/1000)
end

t1:option(DummyValue, "lvw", translate("LastValidWork"))

local stats = luci.controller.cgminer.stats()
t1 = f:section(Table, stats, translate("Avalon Devices Status"))
indicator = t1:option(Button, "_indicator", translate("Indicator"))
function indicator.render(self, section, scope)
        if stats[section].led == '0' then
                self.title = translate("LED OFF")
        else
                self.title = translate("LED ON")
        end

        Button.render(self, section, scope)
end

function indicator.write(self, section)
        cmd = "/usr/bin/cgminer-api " .. "\'ascset|" .. stats[section].devid .. ',led,' .. stats[section].moduleid .. "\'"
        luci.util.execi(cmd)
        if stats[section].led == '0' then
                stats[section].led = '1'
        else
                stats[section].led = '0'
        end
end

t1:option(DummyValue, "elapsed", translate("Elapsed"))
t1:option(DummyValue, "id", translate("Device"))
t1:option(DummyValue, "mm", translate("MM"))
t1:option(DummyValue, "dna", translate("DNA"))
t1:option(DummyValue, "lw", translate("LocalWorks"))
t1:option(DummyValue, "ss", translate("SmartSpeed"))
t1:option(DummyValue, "ghsmm", translate("GHS"))
t1:option(DummyValue, "temp", translate("Temperature(C)"))
t1:option(DummyValue, "fan", translate("Fan(RPM)"))
t1:option(DummyValue, "voltage", translate("InputVoltage(V)"))
t1:option(DummyValue, "pg", translate("PG"))
t1:option(DummyValue, "ec", translate("EC"))

return f
