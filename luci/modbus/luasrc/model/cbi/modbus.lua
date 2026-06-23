-- Copyright 2024 Tailscale for ZLAN9809M Project
-- Licensed under MIT License

local m, s, o

m = Map("modbus", translate("Modbus TCP"),
    translate("Configure Modbus TCP devices for polling and data collection."))

-- Device Configuration Section
s = m:section(TypedSection, "device", translate("Modbus Devices"))
s.addremove = true
s.anonymous = false
s.template = "cbi/tblsection"

-- Enable/Disable
o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false

-- Device Name
o = s:option(Value, "name", translate("Device Name"))
o.rmempty = true

-- IP Address
o = s:option(Value, "ip", translate("IP Address"))
o.rmempty = true
o.datatype = "ipaddr"

-- Port
o = s:option(Value, "port", translate("Port"))
o.rmempty = false
o.default = "502"
o.datatype = "port"

-- Slave ID
o = s:option(Value, "slave_id", translate("Slave ID"))
o.rmempty = false
o.default = "1"
o.datatype = "uinteger"

-- Poll Interval
o = s:option(Value, "poll_interval", translate("Poll Interval (s)"))
o.rmempty = false
o.default = "5"
o.datatype = "uinteger"

-- Timeout
o = s:option(Value, "timeout", translate("Timeout (s)"))
o.rmempty = false
o.default = "3"
o.datatype = "uinteger"

-- Tags Section
s = m:section(TypedSection, "tag", translate("Modbus Tags"))
s.addremove = true
s.anonymous = false
s.template = "cbi/tblsection"

-- Device Reference
o = s:option(ListValue, "device", translate("Device"))
o.rmempty = true
o:depends({device = ""})
o.template = "cbi/dropdown"

-- Tag Name
o = s:option(Value, "name", translate("Tag Name"))
o.rmempty = true

-- Address
o = s:option(Value, "address", translate("Address"))
o.rmempty = true
o.datatype = "uinteger"

-- Type
o = s:option(ListValue, "type", translate("Type"))
o.rmempty = false
o:value("holding", translate("Holding Register"))
o:value("input", translate("Input Register"))
o:value("coil", translate("Coil"))
o:value("discrete", translate("Discrete Input"))
o.default = "holding"

-- Scale
o = s:option(Value, "scale", translate("Scale"))
o.rmempty = false
o.default = "1"
o.datatype = "float"

-- Offset
o = s:option(Value, "offset", translate("Offset"))
o.rmempty = false
o.default = "0"
o.datatype = "float"

-- Status Section
s = m:section(NamedSection, "_status", "modbus", translate("Status"))
s.addremove = false
s.anonymous = true

o = s:option(DummyValue, "_status", translate("Device Status"))
o.rawhtml = true
o.template = "modbus/status"

return m
