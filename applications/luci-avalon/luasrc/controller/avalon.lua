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
		elapsed = '0',
		ghsav = '0',
		ghs5s = '0',
		ghs5m = '0',
		ghs15m = '0',
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
		systime = '0',
		lw = '0',
		hw = '0'
	}

	-- Hashrate
	local summary = luci.util.execi("/usr/bin/cgminer-api -o summary | sed \"s/|/\\n/g\" ")

	if summary then
		for line in summary do
			local elapsed, ghsav, ghs5s, ghs5m, ghs15m = line:match(".*," ..
								"Elapsed=(-?[%d]+)," ..
								"MHS av=(-?[%d%.]+)," ..
								"MHS 5s=(-?[%d%.]+)," ..
								".*," ..
								"MHS 5m=(-?[%d%.]+)," ..
								"MHS 15m=(-?[%d%.]+),")
			if ghsav then
				status.elapsed = elapsed
				status.ghsav = ghsav and (ghsav / 1000) or 0
				status.ghs5s = ghs5s and (ghs5s / 1000) or 0
				status.ghs5m = ghs5m and (ghs5m / 1000) or 0
				status.ghs15m = ghs15m and (ghs15m / 1000) or 0
			end
		end
	end

	-- Modulars information
	local stats = luci.util.execi("/usr/bin/cgminer-api -o estats | sed \"s/|/\\n/g\" | grep AV4 ")
	local devdata = {}
    if stats then
        for line in stats do
            local id, mmver, lw, hw, temp, fan, v, f = 0, 0, 0, 0, 0, 0, 0, 0;
            id = line:match(".*," ..
            "ID=AV4([%d]+),")
            if id then
                local istart, iend = line:find("MM ID")
                while (istart) do
                    local istr = line:sub(istart)
                    local index, mmver, lw, hw, temp, fan, v, f =
                    istr:match("MM ID(%d+)=" ..
                    "Ver%[([%+%-%d%a]+)%]" ..
                    ".-" ..
                    "LW%[(-?%d+)%]" ..
                    ".-" ..
                    "HW%[(-?%d+)%]" ..
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
                        lw = lw,
                        hw = hw,
                        temp = temp,
                        fan = fan,
                        v = v,
                        f = f
                    }
                    istart, iend = line:find("MM ID", iend + 1)
                end
            end
        end
    end

	local modularcnt = table.getn(devdata)
	if modularcnt ~= 0 then
		local mmver, lw, hw, temp, fan, v, f = 0, 0, 0, 0, 0, 0, 0;

		status.modularcnt = modularcnt

		for i, item in ipairs(devdata) do
			mmver = item.mmver
			lw = lw + tonumber(item.lw)
			hw = hw + tonumber(item.hw)
			if temp < tonumber(item.temp) then
			    temp = tonumber(item.temp)
			end
			fan = fan + item.fan
			v = v + item.v
			f = f + item.f
		end

		fan = fan / modularcnt
		v = v / modularcnt
		f = f / modularcnt

		status.mmver = mmver
		status.dh = hw * 100 / lw
		status.lw = lw
		status.hw = hw
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
