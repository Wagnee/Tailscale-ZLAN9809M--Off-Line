-- Copyright 2024 Tailscale for ZLAN9809M Project
-- Licensed under MIT License

local m, s, o

m = Map("mqtt", translate("MQTT Client"),
    translate("Configure MQTT client to publish Modbus tags to an MQTT broker."))

s = m:section(TypedSection, "client", translate("MQTT Configuration"))
s.addremove = false
s.anonymous = true

-- Enable/Disable
o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false

-- Broker URL
o = s:option(Value, "broker", translate("Broker URL"))
o.rmempty = true
o.description = translate("MQTT broker hostname or IP address")

-- Port
o = s:option(Value, "port", translate("Port"))
o.rmempty = false
o.default = "1883"
o.datatype = "port"

-- Username
o = s:option(Value, "username", translate("Username"))
o.rmempty = true
o.description = translate("Leave empty if no authentication required")

-- Password
o = s:option(Value, "password", translate("Password"))
o.rmempty = true
o.password = true
o.description = translate("Leave empty if no authentication required")

-- Client ID
o = s:option(Value, "client_id", translate("Client ID"))
o.rmempty = false
o.default = "zlan9809m"
o.description = translate("Unique identifier for this MQTT client")

-- Keep Alive
o = s:option(Value, "keepalive", translate("Keep Alive (s)"))
o.rmempty = false
o.default = "60"
o.datatype = "uinteger"
o.description = translate("Keep-alive interval in seconds")

-- Topic Prefix
o = s:option(Value, "topic_prefix", translate("Topic Prefix"))
o.rmempty = false
o.default = "zlan9809m"
o.description = translate("Prefix for MQTT topics (e.g., zlan9809m/device/tag)")

-- Status Section
s = m:section(NamedSection, "client", "mqtt", translate("Status"))
s.addremove = false
s.anonymous = true

o = s:option(DummyValue, "_status", translate("Connection Status"))
o.rawhtml = true
o.template = "mqtt/status"

return m
