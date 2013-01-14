module("luci.controller.cgminer", package.seeall)

function index()
   entry({"admin", "status", "cgminer"}, cbi("multiwan/multiwan"), _("Cgminer")).dependent=true
end

