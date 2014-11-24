m = Map("network", "Network")

s = m:section(TypedSection, "interface")
s.addremove = false
s.anonymous = true
function s:filter(value)
    return value =="lan" and value
end

s:depends("proto", "static")
s:depends("proto", "dhcp")

p = s:option(ListValue, "proto", "Protocol")
p:value("static", "static")
p:value("dhcp", "DHCP")
p.default = "static"

ip = s:option(Value, "ipaddr", translate("ip", "IP Address"))
ip:depends("proto", "static")

netmask = s:option(Value, "netmask", "Netmask")
netmask:depends("proto", "static")

gw = s:option(Value, "gateway", "Gateway")
gw:depends("proto", "static")

dns = s:option(Value, "dns", "DNS-Server")
dns:depends("proto", "static")
function dns:validate(value)
    return value:match("[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")
end

return m -- Returns the map
