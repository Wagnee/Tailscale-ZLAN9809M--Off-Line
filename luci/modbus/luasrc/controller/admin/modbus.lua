-- Copyright 2024 Tailscale for ZLAN9809M Project
-- Licensed under MIT License

module("luci.controller.admin.modbus", package.seeall)

function index()
    entry({"admin", "services", "modbus"}, cbi("modbus"), _("Modbus TCP"), 50).dependent = false
    entry({"admin", "services", "modbus", "status"}, call("modbus_status")).leaf = true
end

function modbus_status()
    local uci = luci.model.uci.cursor()
    local status = {
        devices = {}
    }
    
    -- Ler dispositivos configurados
    uci:foreach("modbus", "device", function(s)
        local device = {
            name = s.name or s[".name"],
            enabled = s.enabled or "0",
            ip = s.ip or "-",
            port = s.port or "502",
            slave_id = s.slave_id or "1",
            status = "unknown"
        }
        table.insert(status.devices, device)
    end)
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(status)
end
