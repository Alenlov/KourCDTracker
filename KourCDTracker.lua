local AddonName, KourCDTracker = ...
local AceTimer = LibStub("AceTimer-3.0")


KourCDTracker.CharName = UnitName("player")
KourCDTracker.RealmName = GetRealmName()
KourCDTracker.Token = KourCDTracker.CharName.."-"..KourCDTracker.RealmName
KourCDTracker.Timers = {}
KourCDTracker.SpellIDs = {
	["Tailoring"] = {18560}, --Mooncloth
}



function KourCDTracker:Init()
	-- Setup the DB if needed
	KourCDTracker:SetupDB()

	-- Check if the current character has any cool downs
	KourCDTracker:AddonLoaded()

	local Frame = CreateFrame("Frame", nil, UIParent)

	-- Update the timers every second
	AceTimer:ScheduleRepeatingTimer(KourCDTracker.Tick, 1)

	-- Register event UNIT_SPELLCAST_SUCCEEDED
	Frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	-- Set event handler
	Frame:SetScript("OnEvent", KourCDTracker.HandleEvent)
end

function KourCDTracker:HandleEvent(event, ...)
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		KourCDTracker:SpellCast(self, ...)
	end
end

function KourCDTracker:AddonLoaded()
	for prof, ids in pairs(KourCDTracker.SpellIDs) do
		for _, id in ipairs(ids) do
			if IsSpellKnown(id) then
				print("Spell ID: " .. id .. "is known")
				_, duration = GetSpellCooldown(id)
				local timeFinished = GetServerTime() + duration
				CDTimers[KourCDTracker.Token][prof] = timeFinished
			end
		end
	end
end

function KourCDTracker:SpellCast(self, ... )
	-- body
	local _, _, spellID = ...
	for prof, ids in pairs(KourCDTracker.SpellIDs) do
		for _, id in ipairs(ids) do
			if id == spellID then
				_, duration = GetSpellCooldown(id)
				local timeFinished = GetServerTime() + duration
				CDTimers[KourCDTracker.Token][prof] = timeFinished
			end
		end
	end
end


function KourCDTracker:SetupDB()
	-- body
	if CDTimers == nil then
		CDTimers = {}
		CDTiemrs[KourCDTracker.Token] = {}
	end
	if CDTimers[KourCDTracker.Token] == nil then
		CDTimers[KourCDTracker.Token] = {}
	end

	if CDTimersConfig == nil then
		CDTimersConfig = {}
	end
end

function KourCDTracker:Initialize()
	-- body
	local f = CreateFrame("FRAME")
	f:RegisterEvent("ADDON_LOADED")
	f:SetScript("onEvent", function(self, event, addon)
		if event == "ADDON_LOADED" and addon == AddonName then
			KourCDTracker:Init()
		end
	end)
end

-- Run our initialize script
KourCDTracker:Initialize()

-- Set our addon object as global
_G["KourCDTracker"] = KourCDTracker