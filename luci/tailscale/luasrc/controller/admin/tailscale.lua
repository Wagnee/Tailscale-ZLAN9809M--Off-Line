-- Copyright 2024 Tailscale for ZLAN9809M Project
-- Licensed under MIT License

module("luci.controller.admin.tailscale", package.seeall)

function index()
    entry({"admin", "network", "tailscale"}, cbi("tailscale"), _("Tailscale"), 60).dependent = false
end
