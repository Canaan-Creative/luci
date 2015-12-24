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
	entry({"admin", "status", "cgminer"}, cbi("cgminer/cgminer"), _("Cgminer Configuration"), 90)
	entry({"admin", "status", "cgminerapi"}, call("action_cgminerapi"), _("Cgminer API Log"), 91)
	entry({"admin", "status", "cgminerstatus"}, cbi("cgminer/cgminerstatus"), _("Cgminer Status"), 92)
	entry({"admin", "status", "mmupgrade"}, call("action_mmupgrade"), _("MM Upgrade"), 93)
	entry({"admin", "status", "checkupgrade"}, call("action_checkupgrade"), nil).leaf = true
	entry({"admin", "status", "cgminerstatus", "restart"}, call("action_cgminerrestart"), nil).leaf = true
	entry({"admin", "status", "set_miningmode"}, call("action_setminingmode"), nil).leaf = true
	entry({"admin", "status", "cgminerdebug"}, call("action_cgminerdebug"), nil).leaf = true
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

function valuetodate(elapsed)
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
		return str
	end

	return "date invalid"
end

function summary()
	local data = {}
	local summary = luci.util.execi("/usr/bin/cgminer-api -o summary | sed \"s/|/\\n/g\" ")

	if not summary then
		return
	end

	for line in summary do
		local elapsed, mhsav, foundblocks, getworks, accepted,
		rejected, hw, utility, stale, getfailures,
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
			".*," ..
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
			data[#data+1] = {
				['elapsed'] = valuetodate(elapsed),
				['mhsav'] = num_commas(mhsav),
				['foundblocks'] = foundblocks,
				['getworks'] = num_commas(getworks),
				['accepted'] = num_commas(accepted),
				['rejected'] = num_commas(rejected),
				['hw'] = num_commas(hw),
				['utility'] = num_commas(utility),
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
		local pi, url, st, pri, quo, lp, gw, a, r, sta, gf,
		rf, user, lst, ds, da, dr, dsta, lsd, hs, sa, sd, hg =
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
			".-," ..
			"Has Stratum=(%a+)," ..
			"Stratum Active=(%a+)," ..
			".-," ..
			"Stratum Difficulty=(-?%d+)[%.%d]+," ..
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
				['stratumdifficulty'] = sd,
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
		local id =
		line:match(".*" ..
		"ID=AV4([%d]+),")

		if id then
			local istart, iend = line:find("MM ID")
			while (istart) do
				local istr = line:sub(istart)
				local idname
				local index, idn, dnan, elapsedn, lwn, tempn, temp0n, temp1n, fann, voln, ghsmm, pgn, ledn, ecn =
				istr:match("MM ID(%d+)=" ..
					"Ver%[([%+%-%d%a]+)%]" ..
					".-" ..
					"DNA%[(%x+)%]" ..
					".-" ..
					"Elapsed%[(-?%d+)%]" ..
					".-" ..
					"LW%[(-?%d+)%]" ..
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
					"GHSmm%[(-?[%.%d]+)%]" ..
					".-" ..
					"PG%[(%d+)%]" ..
					".-" ..
					"Led%[(%d)%]" ..
					".-" ..
					"EC%[(%d+)%]")

					if idn ~= nil then
						if string.sub(idn, 1, 2) == '60' then
							idname = 'A60S-'
						else
							idname = 'AV4-'
						end

						data[#data+1] = {
							['devid'] = id,
							['moduleid'] = tostring(index),
							['id'] = idname .. id .. '-' .. tostring(index),
							['mm'] = idn,
							['dna'] = string.sub(dnan, -4, -1),
							['elapsed'] = valuetodate(elapsedn),
							['lw'] = lwn or '0',
							['temp'] = (tempn or '0') .. ' ' .. (temp0n or '0') .. ' ' .. (temp1n or '0'),
							['fan'] = fann or '0',
							['voltage'] = voln or '0',
							['ss'] = 'Enable',
							['ghsmm'] = ghsmm or '0',
							['pg'] = pgn or '0',
							['led'] = ledn or '0',
							['ec'] = ecn or '0'
						}
					end
					istart, iend = line:find("MM ID", iend + 1)
			end
		end
	end

	return data
end

function action_setminingmode()
	local uci = luci.model.uci.cursor()
	local mmode = luci.http.formvalue("mining_mode")
	local modetab = {
			customs = " ",
			normal = "-c /etc/config/a4.normal",
			eco = "-c /etc/config/a4.eco",
			turbo = "-c /etc/config/a4.turbo"
			}

	if modetab[mmode] then
		uci:set("cgminer", "default", "mining_mode", modetab[mmode])
		uci:save("cgminer")
		uci:commit("cgminer")
		if mmode == "customs" then
			luci.http.redirect(
			luci.dispatcher.build_url("admin", "status", "cgminer")
			)
		else
			action_cgminerrestart()
		end
	end
end

function action_mmupgrade()
	local mm_tmp   = "/tmp/mm.mcs"
	local finish_flag   = "/tmp/mm_finish"

	local function mm_upgrade_avail()
		if nixio.fs.access("/usr/bin/mm-tools") then
			return true
		end

		return nil
	end

	local function mm_supported()
		local mm_tmp   = "/tmp/mm.mcs"

		if not nixio.fs.access(mm_tmp) then
			return false
		end

		local filesize = nixio.fs.stat(mm_tmp).size

		-- TODO: Check mm.mcs format
		if filesize == 0 then
			return false
		end
		return true
	end

	local function mm_checksum()
		return (luci.sys.exec("md5sum %q" % mm_tmp):match("^([^%s]+)"))
	end

	local function storage_size()
		local size = 0
		if nixio.fs.access("/proc/mtd") then
			for l in io.lines("/proc/mtd") do
				local d, s, e, n = l:match('^([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+"([^%s]+)"')
				if n == "linux" or n == "firmware" then
					size = tonumber(s, 16)
					break
				end
			end
		elseif nixio.fs.access("/proc/partitions") then
			for l in io.lines("/proc/partitions") do
				local x, y, b, n = l:match('^%s*(%d+)%s+(%d+)%s+([^%s]+)%s+([^%s]+)')
				if b and n and not n:match('[0-9]') then
					size = tonumber(b) * 1024
					break
				end
			end
		end
		return size
	end

	local fp
	luci.http.setfilehandler(
		function(meta, chunk, eof)
			if not fp then
				if meta and meta.name == "image" then
					fp = io.open(mm_tmp, "w")
				end
			end
			if chunk then
				fp:write(chunk)
			end
			if eof and fp then
				fp:close()
			end
		end
	)

	if luci.http.formvalue("image") or luci.http.formvalue("step") then
		--
		-- Check firmware
		--
		local step = tonumber(luci.http.formvalue("step") or 1)
		if step == 1 then
			if mm_supported() == true then
				luci.template.render("mmupgrade", {
					checksum = mm_checksum(),
					storage  = storage_size(),
					size     = nixio.fs.stat(mm_tmp).size,
				})
			else
				nixio.fs.unlink(mm_tmp)
				luci.template.render("mmupload", {
					mm_upgrade_avail = mm_upgrade_avail(),
					mm_image_invalid = true
				})
			end
		--
		--  Upgrade firmware
		--
		elseif step == 2 then
			luci.template.render("mmapply")
			fork_exec("insmod i2c-dev.ko;sleep 1;mmupgrade;touch %q;rmmod i2c-dev" %{ finish_flag })
		elseif step == 3 then
			nixio.fs.unlink(finish_flag)
			luci.template.render("mmapply", {
					finish = 1
				})
		end
	else
		luci.template.render("mmupload", {
			mm_upgrade_avail = mm_upgrade_avail()
		})
	end
end

function action_checkupgrade()
	local status = {}
	local finish_flag   = "/tmp/mm_finish"

	if not nixio.fs.access(finish_flag) then
		status.finish = 0
	else
		status.finish = 1
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end

function fork_exec(command)
	local pid = nixio.fork()
	if pid > 0 then
		return
	elseif pid == 0 then
		-- change to root dir
		nixio.chdir("/")

		-- patch stdin, out, err to /dev/null
		local null = nixio.open("/dev/null", "w+")
		if null then
			nixio.dup(null, nixio.stderr)
			nixio.dup(null, nixio.stdout)
			nixio.dup(null, nixio.stdin)
			if null:fileno() > 2 then
				null:close()
			end
		end

		-- replace with target command
		nixio.exec("/bin/sh", "-c", command)
	end
end

function action_cgminerdebug()
	luci.util.exec("cgminer-api \"debug|D\"")
	luci.http.redirect(
	luci.dispatcher.build_url("admin", "status", "cgminerapi")
	)
end
