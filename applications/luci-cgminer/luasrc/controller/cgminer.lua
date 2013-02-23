module("luci.controller.cgminer", package.seeall)

function index()
   entry({"admin", "status", "cgminer"}, cbi("cgminer/cgminer"), _("Cgminer Configuration"))
   entry({"admin", "status", "cgminerapi"}, call("action_cgminerapi"), _("Cgminer API Log"))
end

function action_cgminerapi()
    local pp   = io.popen("/usr/bin/cgminer-api; /usr/bin/cgminer-api devs; /usr/bin/cgminer-api pools; /usr/bin/cgminer-api stats")
    local data = pp:read("*a")
    pp:close()

    luci.template.render("cgminerapi", {api=data})
end
