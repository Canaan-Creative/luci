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
   entry({"admin", "status", "cgminerapi"}, call("action_cgminerapi"), _("Cgminer API Log"))
end

function action_cgminerapi()
    local pp   = io.popen("/usr/bin/cgminer-api summary; /usr/bin/cgminer-api devs; /usr/bin/cgminer-api pools; /usr/bin/cgminer-api stats")
    local data = pp:read("*a")
    pp:close()

    luci.template.render("cgminerapi", {api=data})
end

function status()
   local data = {}
   local summary = luci.util.execi("/usr/bin/cgminer-api summary")

   if not summary then
      return
   end

   for line in summary do
      local elapsed, mhsav, foundblocks, getworks, accepted, rejected, hw, utility, discarded, stale, getfailures, localwork, remotefailures, networkblocks, totalmh, wu, diffaccepted, diffrejected, diffstale, bestshare = line:match("Elapsed=(%d+),MHS av=([%d%.]+),Found Blocks=(%d+),Getworks=(%d+),Accepted=(%d+),Rejected=(%d+),Hardware Errors=(%d+),Utility=([%d%.]+),Discarded=(%d+),Stale=(%d+),Get Failures=(%d+),Local Work=(%d+),Remote Failures=(%d+),Network Blocks=(%d+),Total MH=([%d%.]+),Work Utility=([%d%.]+),Difficulty Accepted=([%d]+)%.%d+,Difficulty Rejected=([%d]+)%.%d+,Difficulty Stale=([%d]+)%.%d+,Best Share=(%d+)")
      if elapsed then
	 local str
	 local days
	 local h
	 local m
	 local s = elapsed % 60;
	 elapsed = elapsed - s
	 elapsed = elapsed / 60
	 if elapsed == 0 then
	    str = string.format("%ds", second)
	 else
	    m = elapsed % 60;
	    elapsed = elapsed - m
	    elapsed = elapsed / 60
	    if elapsed == 0 then
	       str = sprintf("%dm %ds", m, s);
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
	    ['mhsav'] = mhsav,
	    ['foundblocks'] = foundblocks,
	    ['getworks'] = getworks,
	    ['accepted'] = accepted,
	    ['rejected'] = rejected,
	    ['hw'] = hw,
	    ['utility'] = utility,
	    ['discarded'] = discarded,
	    ['stale'] = stale,
	    ['getfailures'] = getfailures,
	    ['localwork'] = localwork,
	    ['remotefailures'] = remotefailures,
	    ['networkblocks'] = networkblocks,
	    ['totalmh'] = string.format("%e",totalmh),
	    ['wu'] = wu,
	    ['diffaccepted'] = diffaccepted,
	    ['diffrejected'] = diffrejected,
	    ['diffstale'] = diffstale,
	    ['bestshare'] = bestshare
	 }
      end
   end

   return data
end
