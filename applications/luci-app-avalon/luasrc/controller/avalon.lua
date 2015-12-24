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
	local page   = node("avalon")
	page.target  = firstchild()
	page.title   = _("Avalon")
	page.order   = 8
	page.sysauth = "root"
	page.sysauth_authenticator = "avalonauth"

	entry({"avalon"}, alias("avalon", "page", "index"), nil, 90).dependent=false
	entry({"avalon", "page", "index"}, template("page/index"), _("Dashboard"))
	entry({"avalon", "page", "passwdchange"}, cbi("passwdchange"))
	entry({"avalon", "page", "network"}, cbi("network"), _("Network"))
	entry({"avalon", "page", "configure"}, cbi("cgsetting"), _("Configuration"))
	entry({"avalon", "api", "getstatus"}, call("api_getstatus"), nil)
	entry({"avalon", "api", "getlog"}, call("api_getlog"), nil)
	entry({"avalon", "api", "logout"}, call("action_logout"), _("Logout"))
end

function api_getstatus()
	local status = {
		elapsed = nil,
		ghsav = nil,
		ghsmm = nil,
		temp = nil,
		fan = nil,
		voltage = nil,
		modularcnt = 0,
		network = {},
		pool = {},
		openwrtver = nil,
		systime = nil,
	}

	-- Hashrate
	local summary = luci.util.execi("/usr/bin/cgminer-api -o summary | sed \"s/|/\\n/g\" ")

	if summary then
		for line in summary do
			local elapsed, ghsav = line:match(".*," ..
								"Elapsed=(-?[%d]+)," ..
								"MHS av=(-?[%d%.]+),")
			if ghsav then
				status.elapsed = tonumber(elapsed)
				status.ghsav = ghsav and (ghsav / 1000) or 0
			end
		end
	end

	-- Modulars information
	local stats = luci.util.execi("/usr/bin/cgminer-api -o estats | sed \"s/|/\\n/g\" | grep AV4 ")
	local devdata = {}
	if stats then
		for line in stats do
			local id = line:match(".*," ..
				"ID=AV4([%d]+),")
			if id then
				local istart, iend = line:find("MM ID")
				while (istart) do
					local istr = line:sub(istart)
					local index, temp, temp0, temp1, fan, v, ghsmm =
					istr:match("MM ID(%d+)=" ..
					".-" ..
					"Temp%[(-?%d+)%]" ..
					".-" ..
					"Temp0%[(-?%d+)%]" ..
					".-" ..
					"Temp1%[(-?%d+)%]" ..
					".-" ..
					"Fan%[(-?%d+)%]" ..
					".-" ..
					"Vol%[(-?[%.%d]+)%]" ..
					".-" ..
					"GHSmm%[(-?[%.%d]+)%]")

					devdata[#devdata+1] = {
						temp = tonumber(temp),
						temp0 = tonumber(temp0),
						temp1 = tonumber(temp1),
						fan = tonumber(fan),
						v = tonumber(v),
						ghsmm = tonumber(ghsmm)
					}
					istart, iend = line:find("MM ID", iend + 1)
				end
			end
		end
	end

	local modularcnt = table.getn(devdata)
	if modularcnt ~= 0 then
		local temp, fan, v, ghsmm = 0, 0, 0, 0;

		status.modularcnt = modularcnt

		for i, item in ipairs(devdata) do
			if temp < tonumber(item.temp) then
			    temp = tonumber(item.temp)
			end
			if temp < tonumber(item.temp0) then
			    temp = tonumber(item.temp0)
			end
			if temp < tonumber(item.temp1) then
			    temp = tonumber(item.temp1)
			end
			if fan < tonumber(item.fan) then
			    fan = tonumber(item.fan)
			end
			if i == 1 then
			    v = tonumber(item.v)
			end
			if v > tonumber(item.v) then
			    v = tonumber(item.v)
			end
			ghsmm = ghsmm + item.ghsmm
		end

		status.temp = tonumber(temp)
		status.ghsmm = tonumber(ghsmm)
		status.fan = tonumber(fan)
		status.voltage = tonumber(v)
	end

	-- pool info
	local data = {}
	local pools = luci.util.execi("/usr/bin/cgminer-api -o pools | sed \"s/|/\\n/g\" ")

	if pools then
		for line in pools do
			local pool, url, user, diff, accept =
			line:match("POOL=(-?%d+)," ..
				"URL=(.-)," ..
				"Status=Alive.-" ..
				"User=(.-)," ..
				".-" ..
				"Diff1 Shares=(-?%d+)," ..
				".-," ..
				"Difficulty Accepted=(-?%d+)[%.%d]+," ..
				".-" ..
				"Stratum Active=true")
			if pool then
				status.pool[#status.pool+1] = {
					['pool'] = pool,
					['url'] = url,
					['user'] = user,
					['diff'] = tonumber(diff),
					['accept'] = tonumber(accept)
				}
			end
		end
	end

	-- network info
	if nixio.fs.access("/bin/ubus") then
		local netm = require "luci.model.network".init()
		local net = netm:get_network("lan")
		local device = net and net:get_interface()
		if device then
			status.network['mac'] = device:mac()

			local _, a
			for _, a in ipairs(device:ipaddrs()) do
				status.network['ip4'] = a:host():string()
			end
			for _, a in ipairs(device:ip6addrs()) do
				if not a:is6linklocal() then
					status.network['ip6'] = a:host():string()
				end
			end
		end
	end

	local releasedate = io.popen("cat /etc/avalon_version")
	status.openwrtver = releasedate:read("*line")
	releasedate:close()
	status.systime = os.date("%c")

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

function action_logout()
	local dsp = require "luci.dispatcher"
	local sauth = require "luci.sauth"
	if dsp.context.authsession then
		sauth.kill(dsp.context.authsession)
		dsp.context.urltoken.stok = nil
	end

	luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())
	luci.http.redirect(luci.dispatcher.build_url("avalon", "page", "index"))
end
