-- Copyright 2024 Tailscale for ZLAN9809M Project
-- Licensed under MIT License

local m, s, o

m = Map("tailscale", translate("Tailscale VPN"),
    translate("Configure Tailscale to connect your router to your tailnet and advertise routes."))

s = m:section(TypedSection, "tailscale")
s.addremove = false
s.anonymous = true

-- Enable/Disable
o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false

-- Auth Key
o = s:option(Value, "auth_key", translate("Auth Key"))
o.password = true
o.description = translate("Your Tailscale auth key (tskey-auth-...)")

-- Accept Routes
o = s:option(Flag, "accept_routes", translate("Accept Routes"))
o.rmempty = false
o.default = "1"
o.description = translate("Accept routes advertised by other nodes in the tailnet")

-- Accept DNS
o = s:option(Flag, "accept_dns", translate("Accept DNS"))
o.rmempty = false
o.default = "1"
o.description = translate("Accept DNS settings from the tailnet")

-- Advertise Routes
o = s:option(Value, "advertise_routes", translate("Advertise Routes"))
o.description = translate("Comma-separated list of CIDR ranges to advertise (e.g., 192.168.1.0/24)")
o.placeholder = "192.168.1.0/24"

-- Auto-detect DHCP range
o = s:option(Flag, "auto_advertise_dhcp", translate("Auto-detect DHCP Range"))
o.rmempty = false
o.default = "1"
o.description = translate("Automatically detect and advertise the LAN DHCP range")

-- Advertise Exit Node
o = s:option(Flag, "advertise_exit_node", translate("Advertise as Exit Node"))
o.rmempty = false
o.default = "0"
o.description = translate("Advertise this router as an exit node for the tailnet")

-- SSH
o = s:option(Flag, "ssh", translate("Enable Tailscale SSH"))
o.rmempty = false
o.default = "0"
o.description = translate("Enable Tailscale SSH access to this router")

-- State Directory
o = s:option(Value, "state_dir", translate("State Directory"))
o.default = "/etc/tailscale"
o.description = translate("Directory to store Tailscale state files")

-- Status Section
s = m:section(NamedSection, "tailscale", "tailscale", translate("Status"))

o = s:option(DummyValue, "_status", translate("Connection Status"))
o.rawhtml = true
o.template = "tailscale/status"

-- Apply Button
m.submit = function(self)
    return Map.submit(self)
end

return m
