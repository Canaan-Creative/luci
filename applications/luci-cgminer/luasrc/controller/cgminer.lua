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
	    localwork, remotefailures, networkblocks, totalmh, wu,
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
	       		  "Local Work=(-?%d+)," ..
	       		  "Remote Failures=(-?%d+)," ..
	       		  "Network Blocks=(-?%d+)," ..
	       		  "Total MH=(-?[%d%.]+)," ..
	       		  "Work Utility=(-?[%d%.]+)," ..
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
	    ['localwork'] = num_commas(localwork),
	    ['remotefailures'] = remotefailures,
	    ['networkblocks'] = networkblocks,
	    ['totalmh'] = string.format("%e",totalmh),
	    ['wu'] = num_commas(wu),
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
   local devs = luci.util.execi("/usr/bin/cgminer-api -o devs | sed \"s/|/\\n/g\" ")

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
		    "Temperature=(-?[%.%d]+)," ..
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

	local stats = luci.util.execi("/usr/bin/cgminer-api -o stats | sed \"s/|/\\n/g\" | grep AV2 ")

	if not stats then
		return
	end

	for line in stats do
		local id,
		id1, id2, id3, id4,
		lw1, lw2, lw3, lw4,
		dh1, dh2, dh3, dh4,
		t11, t12, t21, t22, t31, t32, t41, t42,
		f11, f12, f21, f22, f31, f32, f41, f42,
		v1, v2, v3, v4,
		f1, f2, f3, f4;
		id =
		line:match(".*," ..
			"ID=AV2([%d]+),")

		if id then
			id1 =
			line:match(".*," ..
				"ID1 MM Version=([%+%-%d%a]+),")

			if id1 then
				lw1, dh1, t11, t12, f11, f12, v1, f1 =
				line:match(".*," ..
					"Local works1=(-?%d+)," ..
					".*" ..
					"Device hardware error1%%=(-?[%.%d]+)," ..
					".*" ..
					"Temperature1=(-?%d+)," ..
					"Temperature2=(-?%d+)," ..
					".*" ..
					"Fan1=(-?%d+)," ..
					"Fan2=(-?%d+)," ..
					".*" ..
					"Voltage1=(-?[%.%d]+)," ..
					".*" ..
					"Frequency1=(-?%d+),")

				data[#data+1] = {
				['devid'] = id,
				['moduleid'] = '1',
				['id'] = 'AV2-' .. id,
				['mm'] = id1,
				['lw'] = lw1 or '0',
				['dh'] = dh1 or '0',
				['temp'] = (t11 or '0') .. '|' .. (t12 or '0'),
				['fan'] = (f11 or '0') .. '|' .. (f12 or '0'),
				['voltage'] = v1 or '0',
				['freq'] = f1 or '0'
				}
			end

			local id2 = line:match(".*," ..
				"ID2 MM Version=([%+%-%d%a]+),")

			if id2 then
				lw2, dh2, t21, t22, f21, f22, v2, f2 =
				line:match(".*," ..
					"Local works2=(-?%d+)," ..
					".*" ..
					"Device hardware error2%%=(-?[%.%d]+)," ..
					".*" ..
					"Temperature3=(-?%d+)," ..
					"Temperature4=(-?%d+)," ..
					".*" ..
					"Fan3=(-?%d+)," ..
					"Fan4=(-?%d+)," ..
					".*" ..
					"Voltage2=([-?%.%d]+)," ..
					".*" ..
					"Frequency2=(-?%d+),")

				data[#data+1] = {
				['devid'] = id,
				['moduleid'] = '2',
				['id'] = 'AV2-' .. id,
				['mm'] = id2,
				['lw'] = lw2 or '0',
				['dh'] = dh2 or '0',
				['temp'] = (t21 or '0') .. '|' .. (t22 or '0'),
				['fan'] = (f21 or '0') .. '|' .. (f22 or '0'),
				['voltage'] = v2 or '0',
				['freq'] = f2 or '0'
				}
			end


			local id3 = line:match(".*," ..
				"ID3 MM Version=([%+%-%d%a]+),")

			if id3 then
				lw3, dh3, t31, t32, f31, f32, v3, f3 =
				line:match(".*," ..
					"Local works3=(-?%d+)," ..
					".*" ..
					"Device hardware error3%%=([-?%.%d]+)," ..
					".*" ..
					"Temperature5=(-?%d+)," ..
					"Temperature6=(-?%d+)," ..
					".*" ..
					"Fan5=(-?%d+)," ..
					"Fan6=(-?%d+)," ..
					".*" ..
					"Voltage3=([-?%.%d]+)," ..
					".*" ..
					"Frequency3=(-?%d+),")

				data[#data+1] = {
				['devid'] = id,
				['moduleid'] = '3',
				['id'] = 'AV2-' .. id,
				['mm'] = id3,
				['lw'] = lw3 or '0',
				['dh'] = dh3 or '0',
				['temp'] = (t31 or '0') .. '|' .. (t32 or '0'),
				['fan'] = (f31 or '0') .. '|' .. (f32 or '0'),
				['voltage'] = v3 or '0',
				['freq'] = f3 or '0'
				}
			end

			local id4 = line:match(".*," ..
				"ID4 MM Version=([%+%-%d%a]+),")

			if id4 then
				lw4, dh4, t41, t42, f41, f42, v4, f4 =
				line:match(".*," ..
					"Local works4=(-?%d+)," ..
					".*" ..
					"Device hardware error4%%=([-?%.%d]+)," ..
					".*" ..
					"Temperature7=(-?%d+)," ..
					"Temperature8=(-?%d+)," ..
					".*" ..
					"Fan7=(-?%d+)," ..
					"Fan8=(-?%d+)," ..
					".*" ..
					"Voltage4=([-?%.%d]+)," ..
					".*" ..
					"Frequency4=(-?%d+),")

				data[#data+1] = {
				['devid'] = id,
				['moduleid'] = '4',
				['id'] = 'AV2-' .. id,
				['mm'] = id4,
				['lw'] = lw4 or '0',
				['dh'] = dh4 or '0',
				['temp'] = (t41 or '0') .. '|' .. (t42 or '0'),
				['fan'] = (f41 or '0') .. '|' .. (f42 or '0'),
				['voltage'] = v4 or '0',
				['freq'] = f4 or '0'
				}
			end
		end
	end

	return data
end
