module("luci.controller.cpufreq", package.seeall)

function index()
    entry({"admin", "services", "cpufreq"}, cbi("cpufreq"), translate("CPU Management"), 60)
    entry({"admin", "services", "cpufreq", "governor"}, call("get_governor"))
    entry({"admin", "services", "cpufreq", "temperature"}, call("get_temperature"))
    entry({"admin", "services", "cpufreq", "frequency"}, call("get_frequency"))
    entry({"admin", "services", "cpufreq", "max_frequency"}, call("get_max_frequency"))
end

function get_governor()
    local governor = io.popen("/usr/bin/cpu-governor-manager.sh get"):read("*a")
    luci.http.prepare_content("application/json")
    luci.http.write_json({governor = governor:gsub("\n", "")})
end

function get_temperature()
    local temp = io.popen("/usr/bin/cpu-governor-manager.sh temp"):read("*a")
    luci.http.prepare_content("application/json")
    luci.http.write_json({temperature = temp:gsub("\n", "")})
end

function get_frequency()
    local freq = io.popen("/usr/bin/cpu-governor-manager.sh status | grep 'Frequência atual'"):read("*a")
    if freq then
        freq = freq:match("Frequência atual: ([^\n]+)")
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json({frequency = freq or "N/A"})
end

function get_max_frequency()
    local freq = io.popen("/usr/bin/cpu-governor-manager.sh status | grep 'Frequência máxima'"):read("*a")
    if freq then
        freq = freq:match("Frequência máxima: ([^\n]+)")
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json({frequency = freq or "N/A"})
end
