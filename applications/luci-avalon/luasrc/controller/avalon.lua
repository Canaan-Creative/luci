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
	local root = node()
	if not root.target then
		root.target = alias("avalon")
		root.index = true
	end

	local page   = node("avalon")
	page.target  = firstchild()
	page.title   = _("Avalon")
	page.order   = 8
	page.sysauth = "root"
	page.sysauth_authenticator = "sbadminauth"
	page.ucidata = true
	page.index = true

	entry({"avalon"}, alias("avalon", "page", "index"), nil, 90).dependent=false
	entry({"avalon", "page", "index"}, template("page/index"), _("Dashboard"))
	entry({"avalon", "page", "network"}, cbi("network"), _("Network"))
	entry({"avalon", "page", "configure"}, cbi("cgsetting"), _("Configuration"))
	entry({"avalon", "api", "getstatus"}, call("api_getstatus"), nil)
	entry({"avalon", "api", "getlog"}, call("api_getlog"), nil)
	entryauth({"avalon", "api", "changetheme"}, call("api_changetheme"), nil, nil, false)
	entry({"avalon", "api", "logout"}, call("action_logout"), _("Logout"))
end

function api_getstatus()
	local status = {
		ghsav = '0',
		ghs5s = '0',
		ghs5m = '0',
		hashrate = {},
		temp = '0',
		fan = '0',
		voltage = '0',
		freq = '0',
		modularcnt = '0',
		dh = 0,
		mmver = '0',
		network = {},
		pool = {},
		openwrtver = '0',
		systime = '0'
	}

	-- Hashrate
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

	-- Modulars information
	local stats = luci.util.execi("/usr/bin/cgminer-api -o estats | sed \"s/|/\\n/g\" | grep AV4 ")
	local devdata = {}
	if stats then
		for line in stats do
			local id, mmver, dh, temp, fan, v, f;
			id = line:match(".*," ..
			"ID=AV4([%d]+),")
			if id then
				for index=1,64 do
					mmver = line:match(".-," ..
					"MM ID" ..
					tostring(index) ..
					"=Ver%[([%+%-%d%a]+)%]")
					if mmver then
						dh, temp, fan, v, f =
						line:match("MM ID" ..
						tostring(index) ..
						"=Ver.-" ..
						".-" ..
						"DH%[(-?[%.%d]+%%)%]" ..
						".-" ..
						"Temp%[(-?%d+)%]" ..
						".-" ..
						"Fan%[(-?%d+)%]" ..
						".-" ..
						"Vol%[(-?[%.%d]+)%]" ..
						".-" ..
						"Freq%[(-?[%.%d]+)%]")

						devdata[#devdata+1] = {
							mmver = mmver,
							dh = dh,
							temp = temp,
							fan = fan,
							v = v,
							f = f
						}
					end
				end
			end
		end
	end

	local modularcnt = table.getn(devdata)
	if modularcnt ~= 0 then
		local mmver, dh, temp, fan, v, f = 0, 0.0, 0, 0, 0, 0;

		status.modularcnt = modularcnt

		for i, item in ipairs(devdata) do
			mmver = item.mmver
			dh = item.dh
			temp =  temp + item.temp
			fan = fan + item.fan
			v = v + item.v
			f = f + item.f
		end

		temp = temp / modularcnt
		fan = fan / modularcnt
		v = v / modularcnt
		f = f / modularcnt

		status.mmver = mmver
		status.dh = dh
		status.temp = temp
		status.fan = fan
		status.voltage = v
		status.freq = f
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

	-- pool info
	local data = {}
	local pools = luci.util.execi("/usr/bin/cgminer-api -o pools | sed \"s/|/\\n/g\" ")

	if pools then
		for line in pools do
			local pool, url, diff, accept =
			line:match("POOL=(-?%d+)," ..
				"URL=(.-)," ..
				".*" ..
				"Diff1 Shares=(-?%d+)," ..
				".*," ..
				"Difficulty Accepted=(-?%d+)[%.%d]+,")
			if pool then
				status.pool[#status.pool+1] = {
					['pool'] = pool,
					['url'] = url,
					['diff'] = diff,
					['accept'] = accept
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

	status.openwrtver = luci.version.distname .. luci.version.distversion
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

function api_changetheme()
	local msg = {}
	local uci = require "luci.model.uci".cursor()
	local theme = luci.http.formvalue("theme")

	msg.ret = 1
	msg.result = "theme param is null,(openwrt/sbadmin)"

	if theme == "openwrt" then
		uci:set("luci", "main", "mediaurlbase", "/luci-static/openwrt.org")
		uci:commit("luci")
		msg.ret = 0
		msg.result = "Change to openwrt"
	end

	if theme == "sbadmin" then
		uci:set("luci", "main", "mediaurlbase", "/luci-static/sbadmin")
		uci:commit("luci")
		msg.ret = 0
		msg.result = "Change to sbadmin"
	end

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
