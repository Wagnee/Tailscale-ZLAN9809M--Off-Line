-- Copyright 2024 Tailscale for ZLAN9809M Project
-- Licensed under MIT License

module("luci.controller.admin.tailscale_status", package.seeall)

function index()
    entry({"admin", "network", "tailscale", "status"}, call("status")).dependent = false
end

function status()
    local info = {
        status = "Disconnected",
        ip = "",
        tailnet = "",
        routes = ""
    }

    -- Check if tailscale binary exists
    local f = io.popen("/usr/sbin/tailscale status --json 2>/dev/null")
    if f then
        local output = f:read("*a")
        f:close()

        if output and output ~= "" then
            -- Parse JSON (simple parsing)
            local success, data = pcall(function() return require("luci.jsonc").parse(output) end)
            if success and data then
                if data.BackendState then
                    info.status = data.BackendState
                end
                if data.Self and data.Self.TailscaleIPs and #data.Self.TailscaleIPs > 0 then
                    info.ip = data.Self.TailscaleIPs[1]
                end
                if data.Self and data.Self.DNSName then
                    info.tailnet = data.Self.DNSName:match("(.*)%.")
                end
                if data.Self and data.Self.AdvertisedRoutes and #data.Self.AdvertisedRoutes > 0 then
                    info.routes = table.concat(data.Self.AdvertisedRoutes, ", ")
                end
            end
        end
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(info)
end
