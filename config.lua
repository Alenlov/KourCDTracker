local ConfigKey = "cdtracker"

local options = {
	type = "group",
	name = "Kour CD Tracker"
}

LibStub("AceConfig-3.0"):RegisterOptionsTable(ConfigKey, options)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ConfigKey, "Kour CD Tracker")