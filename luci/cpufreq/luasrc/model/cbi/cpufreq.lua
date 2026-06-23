local m, s, o

m = Map("cpufreq", translate("CPU Frequency Management"),
    translate("Manage CPU frequency scaling governor and monitor temperature"))

s = m:section(TypedSection, "settings")
s.addremove = false
s.anonymous = true

-- Governor Selection
o = s:option(ListValue, "governor", translate("CPU Governor"))
o:value("performance", translate("Performance (Maximum Frequency)"))
o:value("ondemand", translate("Ondemand (Dynamic)"))
o:value("conservative", translate("Conservative (Balanced)"))
o:value("powersave", translate("Powersave (Minimum Frequency)"))
o.description = translate("Select CPU frequency governor based on environment")

-- Current Status Section
s = m:section(NamedSection, "settings", "settings", translate("Current Status"))

o = s:option(DummyValue, "_governor", translate("Current Governor"))
o.rawhtml = true
o.template = "cpufreq/governor"

o = s:option(DummyValue, "_temperature", translate("CPU Temperature"))
o.rawhtml = true
o.template = "cpufreq/temperature"

o = s:option(DummyValue, "_frequency", translate("Current Frequency"))
o.rawhtml = true
o.template = "cpufreq/frequency"

o = s:option(DummyValue, "_max_frequency", translate("Maximum Frequency"))
o.rawhtml = true
o.template = "cpufreq/max_frequency"

-- Apply Button
m.submit = function(self)
    return Map.submit(self)
end

return m
