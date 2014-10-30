--[[
LuCI - Lua Configuration Interface

Copyright 2014 Mikeqin <Fengling.Qin@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: init.lua 6731 2011-01-14 19:44:03Z soma $
]]--

module("luci.controller.avalon", package.seeall)

function index()
	entry({"avalon"}, alias("avalon", "page", "index"), _("Index"), 90).dependent=false
	entry({"avalon", "page", "index"}, template("page/index"), _("Index"))
	entry({"avalon", "page", "login"}, template("page/login"), _("Login"))
	entry({"avalon", "page", "network"}, template("page/network"), _("Network"))
	entry({"avalon", "page", "cf"}, template("page/cf"), _("Cf"))
	entry({"avalon", "page", "blank"}, template("page/blank"), _("Blank"))
	entry({"avalon", "page", "ui"}, template("page/ui"), _("UI"))
	entry({"avalon", "page", "tab-panel"}, template("page/tab-panel"), _("Tabe-panel"))
	entry({"avalon", "network", "wan"}, cbi("wan"), _("Network"))
	entry({"avalon", "page", "cgsetting"}, cbi("cgsetting"), _("CGSetting"))
	entry({"avalon", "api", "getstatus"}, call("api_getstatus"), nil)
	entry({"avalon", "api", "getlog"}, call("api_getlog"), nil).dependent=false
end

function api_getstatus()
	local status = {
		ghsav = '290',
		ghs5s = '291',
		ghs5m = '292',
		hashrate = {},
		temp = '30',
		fan = '6670',
		voltage = '7000',
		freq = '500',
		modularcnt = '0'
	}

	local summary = luci.util.execi("/usr/bin/cgminer-api -o summary | sed \"s/|/\\n/g\" ")

	if summary then
	    	for line in summary do
			local ghsav, ghs5s, ghs5m = line:match(".*," ..
								"MHS av=(-?[%d%.]+)," ..
								"MHS 5s=(-?[%d%.]+)," ..
								".*," ..
								"MHS 5m=(-?[%d%.]+),")
			if ghsav then
				status.ghsav = ghsav and (ghsav / 1000) or 0
				status.ghs5s = ghs5s and (ghs5s / 1000) or 0
				status.ghs5m = ghs5m and (ghs5m / 1000) or 0
			end
		end
	end

	local stats = luci.util.execi("/usr/bin/cgminer-api -o estats | sed \"s/|/\\n/g\" | grep AV2 ")
	local devdata = {}
	if stats then
		for line in stats do
			local id, temp1, temp2, fan1, fan2, v, f;
			id = line:match(".*," ..
					"ID=AV2([%d]+),")
			if id then
				id = line:match(".*," ..
						"ID1 MM Version=([%+%-%d%a]+),")
				if id then
					temp1, temp2, fan1, fan2, v, f =
					line:match(".*," ..
					"Temperature1=(-?%d+)," ..
					"Temperature2=(-?%d+)," ..
					".*" ..
					"Fan1=(-?%d+)," ..
					"Fan2=(-?%d+)," ..
					".*" ..
					"Voltage1=(-?[%.%d]+)," ..
					".*" ..
					"Frequency1=(-?%d+),")

					devdata[#devdata+1] = {
						temp1 = temp1,
						temp2 = temp2,
						fan1 = fan1,
						fan2 = fan2,
						v = v,
						f = f
					}
				end

				id = line:match(".*," ..
						"ID2 MM Version=([%+%-%d%a]+),")

				if id then
					temp1, temp2, fan1, fan2, v, f =
					line:match(".*," ..
					"Temperature3=(-?%d+)," ..
					"Temperature4=(-?%d+)," ..
					".*" ..
					"Fan3=(-?%d+)," ..
					"Fan4=(-?%d+)," ..
					".*" ..
					"Voltage2=(-?[%.%d]+)," ..
					".*" ..
					"Frequency2=(-?%d+),")

					devdata[#devdata+1] = {
						temp1 = temp1,
						temp2 = temp2,
						fan1 = fan1,
						fan2 = fan2,
						v = v,
						f = f
					}
				end

				id = line:match(".*," ..
						"ID3 MM Version=([%+%-%d%a]+),")

				if id then
					temp1, temp2, fan1, fan2, v, f =
					line:match(".*," ..
					"Temperature5=(-?%d+)," ..
					"Temperature6=(-?%d+)," ..
					".*" ..
					"Fan5=(-?%d+)," ..
					"Fan6=(-?%d+)," ..
					".*" ..
					"Voltage3=(-?[%.%d]+)," ..
					".*" ..
					"Frequency3=(-?%d+),")

					devdata[#devdata+1] = {
						temp1 = temp1,
						temp2 = temp2,
						fan1 = fan1,
						fan2 = fan2,
						v = v,
						f = f
					}
				end

				id = line:match(".*," ..
						"ID4 MM Version=([%+%-%d%a]+),")

				if id then
					temp1, temp2, fan1, fan2, v, f =
					line:match(".*," ..
					"Temperature7=(-?%d+)," ..
					"Temperature8=(-?%d+)," ..
					".*" ..
					"Fan7=(-?%d+)," ..
					"Fan8=(-?%d+)," ..
					".*" ..
					"Voltage4=(-?[%.%d]+)," ..
					".*" ..
					"Frequency4=(-?%d+),")

					devdata[#devdata+1] = {
						temp1 = temp1,
						temp2 = temp2,
						fan1 = fan1,
						fan2 = fan2,
						v = v,
						f = f
					}
				end
			end
		end
	end

	local modularcnt = table.getn(devdata)
	if modularcnt ~= 0 then
		local temp, fan, v, f = 0, 0, 0, 0;

		status.modularcnt = modularcnt

		for i, item in ipairs(devdata) do
			temp =  temp + (item.temp1 and item.temp1 or item.temp2)
			fan = fan + (item.fan1 and item.fan1 or item.fan2)
			v = v + item.v
			f = f + item.f
		end

		temp = temp / modularcnt
		fan = fan / modularcnt
		v = v / modularcnt
		f = f / modularcnt
		status.temp = temp
		status.fan = fan
		status.voltage = v
		status.freq = f
	else
		-- random data
		math.randomseed(os.time())
		status.temp = math.random(0,100)
		status.fan = math.random(0,7000)
		status.ghsav = math.random(200, 300)
	end

	local devs = luci.util.execi("/usr/bin/cgminer-api -o edevs | sed \"s/|/\\n/g\" ")

	if devs then
		for line in devs do
			local asc, name, id, mhsav =
			line:match("ASC=(%d+)," ..
				"Name=([%a%d]+)," ..
				"ID=(%d+)," ..
				".*," ..
				"MHS av=(-?[%.%d]+),")

			if asc then
				status.hashrate[#status.hashrate+1] = {
					name = "ASC" .. asc .. "-" .. name .. "-" .. id,
					ghsav = mhsav /1000
				}
			end
		end
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end

function api_getlog()
	local msg = {}
	local pp   = io.popen("echo -n \"[Firmware Version] => \"; cat /etc/avalon_version; /usr/bin/cgminer-api stats;")
	msg.log = pp:read("*a")
	pp:close()

	luci.http.prepare_content("application/json")
	luci.http.write_json(msg)
end
