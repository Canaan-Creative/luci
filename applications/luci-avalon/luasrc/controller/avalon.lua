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
	entry({"avalon", "page", "table"}, template("page/table"), _("Table"))
	entry({"avalon", "page", "form"}, template("page/form"), _("Form"))
	entry({"avalon", "page", "chart"}, template("page/chart"), _("Chart"))
	entry({"avalon", "page", "blank"}, template("page/blank"), _("Blank"))
	entry({"avalon", "page", "ui"}, template("page/ui"), _("UI"))
	entry({"avalon", "page", "tab-panel"}, template("page/tab-panel"), _("Tabe-panel"))
end
