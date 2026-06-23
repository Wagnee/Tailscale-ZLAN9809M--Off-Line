-- Copyright 2024 Tailscale for ZLAN9809M Project
-- Licensed under MIT License

module("luci.controller.admin.mqtt", package.seeall)

function index()
    entry({"admin", "services", "mqtt"}, cbi("mqtt"), _("MQTT Client"), 51).dependent = false
    entry({"admin", "services", "mqtt", "status"}, call("mqtt_status")).leaf = true
end

function mqtt_status()
    local uci = luci.model.uci.cursor()
    local status = {
        enabled = "0",
        broker = "-",
        port = "-",
        connection_status = "unknown"
    }
    
    -- Ler configuração MQTT
    local mqtt_config = uci:get_all("mqtt", "client") or {}
    status.enabled = mqtt_config.enabled or "0"
    status.broker = mqtt_config.broker or "-"
    status.port = mqtt_config.port or "-"
    
    -- Tentar ler status do daemon (se estiver rodando)
    local f = io.open("/var/run/mqtt-daemon.status", "r")
    if f then
        status.connection_status = f:read("*all") or "unknown"
        f:close()
    else
        status.connection_status = "daemon_not_running"
    end
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(status)
end
