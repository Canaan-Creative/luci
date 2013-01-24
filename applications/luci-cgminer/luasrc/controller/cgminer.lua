module("luci.controller.cgminer", package.seeall)

function index()
   entry({"admin", "status", "cgminer"}, cbi("cgminer/cgminer"), _("Cgminer Configuration"))
   entry({"admin", "status", "cgminerstatus"}, call("action_cstatus"), _("Cgminer Status"))
end

function action_cstatus()
    local pp   = io.popen("/usr/bin/cgminer-api; /usr/bin/cgminer-api devs; /usr/bin/cgminer-api pools; /usr/bin/cgminer-api stats")
    local data = pp:read("*a")
    pp:close()

    luci.template.render("cgminerstatus", {cstatus=data})
end
