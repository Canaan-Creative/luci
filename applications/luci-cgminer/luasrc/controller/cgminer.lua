--[[
LuCI - Lua Configuration Interface

Copyright 2013 Xiangfu

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

module("luci.controller.cgminer", package.seeall)

function index()
	entry({"admin", "status", "cgminer"}, cbi("cgminer/cgminer"), _("Cgminer Configuration"))
	entry({"admin", "status", "cgminerstatus"}, cbi("cgminer/cgminerstatus"), _("Cgminer Status"))
	entry({"admin", "status", "cgminerstatus", "restart"}, call("action_cgminerrestart"), nil).leaf = true
	entry({"admin", "status", "cgminerapi"}, call("action_cgminerapi"), _("Cgminer API Log"))
end

function action_cgminerrestart()
	luci.util.exec("/etc/init.d/cgminer restart")
	luci.http.redirect(
	luci.dispatcher.build_url("admin", "status", "cgminerstatus")
	)
end

function action_cgminerapi()
	local pp   = io.popen("echo -n \"[Firmware Version] => \"; cat /etc/avalon_version; /usr/bin/cgminer-api stats;")
	local data = pp:read("*a")
	pp:close()

	luci.template.render("cgminerapi", {api=data})
end

function num_commas(n)
	return tostring(math.floor(n)):reverse():gsub("(%d%d%d)","%1,"):gsub(",(%-?)$","%1"):reverse()
end

function summary()
	local data = {}
	local summary = luci.util.execi("/usr/bin/cgminer-api -o summary | sed \"s/|/\\n/g\" ")

	if not summary then
		return
	end

	for line in summary do
		local elapsed, mhsav, foundblocks, getworks, accepted,
		rejected, hw, utility, discarded, stale, getfailures,
		remotefailures, networkblocks, totalmh,
		diffaccepted, diffrejected, diffstale, bestshare =
		line:match(".*," ..
			"Elapsed=(-?%d+)," ..
			"MHS av=(-?[%d%.]+)," ..
			".*," ..
			"Found Blocks=(-?%d+)," ..
			"Getworks=(-?%d+)," ..
			"Accepted=(-?%d+)," ..
			"Rejected=(-?%d+)," ..
			"Hardware Errors=(-?%d+)," ..
			"Utility=([-?%d%.]+)," ..
			"Discarded=(-?%d+)," ..
			"Stale=(-?%d+)," ..
			"Get Failures=(-?%d+)," ..
			".-" ..
			"Remote Failures=(-?%d+)," ..
			"Network Blocks=(-?%d+)," ..
			"Total MH=(-?[%d%.]+)," ..
			".-" ..
			"Difficulty Accepted=(-?[%d]+)%.%d+," ..
			"Difficulty Rejected=(-?[%d]+)%.%d+," ..
			"Difficulty Stale=(-?[%d]+)%.%d+," ..
			"Best Share=(-?%d+)")
		if elapsed then
			local str
			local days
			local h
			local m
			local s = elapsed % 60;
			elapsed = elapsed - s
			elapsed = elapsed / 60
			if elapsed == 0 then
				str = string.format("%ds", s)
			else
				m = elapsed % 60;
				elapsed = elapsed - m
				elapsed = elapsed / 60
				if elapsed == 0 then
					str = string.format("%dm %ds", m, s);
				else
					h = elapsed % 24;
					elapsed = elapsed - h
					elapsed = elapsed / 24
					if elapsed == 0 then
						str = string.format("%dh %dm %ds", h, m, s)
					else
						str = string.format("%dd %dh %dm %ds", elapsed, h, m, s);
					end
				end
			end

			data[#data+1] = {
				['elapsed'] = str,
				['mhsav'] = num_commas(mhsav),
				['foundblocks'] = foundblocks,
				['getworks'] = num_commas(getworks),
				['accepted'] = num_commas(accepted),
				['rejected'] = num_commas(rejected),
				['hw'] = num_commas(hw),
				['utility'] = num_commas(utility),
				['discarded'] = num_commas(discarded),
				['stale'] = stale,
				['getfailures'] = getfailures,
				['remotefailures'] = remotefailures,
				['networkblocks'] = networkblocks,
				['totalmh'] = string.format("%e",totalmh),
				['diffaccepted'] = num_commas(diffaccepted),
				['diffrejected'] = num_commas(diffrejected),
				['diffstale'] = diffstale,
				['bestshare'] = num_commas(bestshare)
			}
		end
	end

	return data
end

function pools()
	local data = {}
	local pools = luci.util.execi("/usr/bin/cgminer-api -o pools | sed \"s/|/\\n/g\" ")

	if not pools then
		return
	end

	for line in pools do
		local pi, url, st, pri, quo, lp, gw, a, r, dc, sta, gf,
		rf, user, lst, ds, da, dr, dsta, lsd, hs, sa, su, hg =
		line:match("POOL=(-?%d+)," ..
			"URL=(.*)," ..
			"Status=(%a+)," ..
			"Priority=(-?%d+)," ..
			"Quota=(-?%d+)," ..
			"Long Poll=(%a+)," ..
			"Getworks=(-?%d+)," ..
			"Accepted=(-?%d+)," ..
			"Rejected=(-?%d+)," ..
			".*," ..
			"Discarded=(-?%d+)," ..
			"Stale=(-?%d+)," ..
			"Get Failures=(-?%d+)," ..
			"Remote Failures=(-?%d+)," ..
			"User=(.*)," ..
			"Last Share Time=(-?%d+)," ..
			"Diff1 Shares=(-?%d+)," ..
			".*," ..
			"Difficulty Accepted=(-?%d+)[%.%d]+," ..
			"Difficulty Rejected=(-?%d+)[%.%d]+," ..
			"Difficulty Stale=(-?%d+)[%.%d]+," ..
			"Last Share Difficulty=(-?%d+)[%.%d]+," ..
			"Has Stratum=(%a+)," ..
			"Stratum Active=(%a+)," ..
			"Stratum URL=.*," ..
			"Has GBT=(%a+)")
		if pi then
			if lst == "0" then
				lst_date = "Never"
			else
				lst_date = os.date("%c", lst)
			end
			data[#data+1] = {
				['pool'] = pi,
				['url'] = url,
				['status'] = st,
				['priority'] = pri,
				['quota'] = quo,
				['longpoll'] = lp,
				['getworks'] = gw,
				['accepted'] = a,
				['rejected'] = r,
				['discarded'] = dc,
				['stale'] = sta,
				['getfailures'] = gf,
				['remotefailures'] = rf,
				['user'] = user,
				['lastsharetime'] = lst_date,
				['diff1shares'] = ds,
				['diffaccepted'] = da,
				['diffrejected'] = dr,
				['diffstale'] = dsta,
				['lastsharedifficulty'] = lsd,
				['hasstratum'] = hs,
				['stratumactive'] = sa,
				['stratumurl'] = su,
				['hasgbt'] = hg
			}
		end
	end

	return data
end

function devs()
	local data = {}
	local devs = luci.util.execi("/usr/bin/cgminer-api -o edevs | sed \"s/|/\\n/g\" ")

	if not devs then
		return
	end

	for line in devs do
		local asc, name, id, enabled, status, temp, mhsav, mhs5s, mhs1m, mhs5m, mhs15m, lvw, dh =
		line:match("ASC=(%d+)," ..
			"Name=([%a%d]+)," ..
			"ID=(%d+)," ..
			"Enabled=(%a+)," ..
			"Status=(%a+)," ..
			"Temperature=(-?[%d]+).%d+," ..
			"MHS av=(-?[%.%d]+)," ..
			"MHS 5s=(-?[%.%d]+)," ..
			"MHS 1m=(-?[%.%d]+)," ..
			"MHS 5m=(-?[%.%d]+)," ..
			"MHS 15m=(-?[%.%d]+)," ..
			".*," ..
			"Last Valid Work=(-?%d+)," ..
			"Device Hardware%%=(-?[%.%d]+)")

		if lvw == "0" then
			lvw_date = "Never"
		else
			lvw_date = os.date("%c", lst)
		end

		if asc then
			data[#data+1] = {
				['name'] = "ASC" .. asc .. "-" .. name .. "-" .. id,
				['enable'] = enabled,
				['status'] = status,
				['temp'] = temp,
				['mhsav'] = mhsav,
				['mhs5s'] = mhs5s,
				['mhs1m'] = mhs1m,
				['mhs5m'] = mhs5m,
				['mhs15m'] = mhs15m,
				['lvw'] = lvw_date
			}
		end
	end

	return data
end

function stats()
	local data = {}

	local stats = luci.util.execi("/usr/bin/cgminer-api -o estats | sed \"s/|/\\n/g\" | grep AV4 ")

	if not stats then
		return
	end

	for line in stats do
		local id,
		idn;
		id =
		line:match(".*" ..
		"ID=AV4([%d]+),")

		if id then
			for index=1,64 do
				idn =
				line:match(".-" ..
				"MM ID" ..
				tostring(index) ..
				"=Ver%[([%+%-%d%a]+)%]")

				if idn then
					local dnan, lwn, dhn, ghs5mn, dh5mn, tempn, fann, voln, freqn, ledn =
					line:match("MM ID" ..
					tostring(index) ..
					"=Ver.-" ..
					"DNA%[(%x+)%]" ..
					".-" ..
					"LW%[(-?%d+)%]" ..
					".-" ..
					"DH%[(-?[%.%d]+%%)%]" ..
					".-" ..
					"GHS5m%[(-?[%.%d]+)%]" ..
					".-" ..
					"DH5m%[(-?[%.%d]+%%)%]" ..
					".-" ..
					"Temp%[(-?%d+)%]" ..
					".-" ..
					"Fan%[(-?%d+)%]" ..
					".-" ..
					"Vol%[(-?[%.%d]+)%]" ..
					".-" ..
					"Freq%[(-?[%.%d]+)%]" ..
					".-" ..
					"Led%[(%d)%]")

					data[#data+1] = {
						['devid'] = id,
						['moduleid'] = tostring(index),
						['id'] = 'AV4-' .. id .. '-' .. tostring(index),
						['mm'] = idn,
						['dna'] = string.sub(dnan, -4, -1),
						['lw'] = lwn or '0',
						['dh'] = dhn or '0',
						['ghs5m'] = ghs5mn or '0',
						['dh5m'] = dh5mn or '0',
						['temp'] = tempn or '0',
						['fan'] = fann or '0',
						['voltage'] = voln or '0',
						['freq'] = freqn or '0',
						['led'] = ledn or '0'
					}
				end
			end
		end
	end

	return data
end
