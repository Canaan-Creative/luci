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
	entry({"avalon"}, alias("avalon", "page", "index"), _("Index"), 90).dependent=false
	entry({"avalon", "page", "index"}, template("page/index"), _("Index"))
	entry({"avalon", "page", "tables"}, template("page/tables"), _("Table"))
	entry({"avalon", "page", "forms"}, template("page/forms"), _("Forms"))
	entry({"avalon", "page", "charts"}, template("page/charts"), _("Charts"))
	entry({"avalon", "page", "blank-page"}, template("page/blank-page"), _("Blank-page"))
	entry({"avalon", "page", "bootstrap-grid"}, template("page/bootstrap-grid"), _("Bootstrap-grid"))
	entry({"avalon", "page", "bootstrap-elements"}, template("page/bootstrap-elements"), _("Bootstrap-elements"))
end
