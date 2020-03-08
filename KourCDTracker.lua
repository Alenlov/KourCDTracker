local AddonName, KourCDTracker = ...
local AceTimer = LibStub("AceTimer-3.0")


KourCDTracker.CharName = UnitName("player")
KourCDTracker.RealmName = GetRealmName()
KourCDTracker.Token = KourCDTracker.CharName.."-"..KourCDTracker.RealmName
KourCDTracker.Timers = {}
KourCDTracker.SpellIDs = {
	["Tailoring"] = 18560, --Mooncloth
	["Alchemy"] = 17187
}
KourCDTracker.SkillCheck = {
	["Tailoring"] = 250,
	["Alchemy"] = 275
}
KourCDTracker.Checked = 0

function KourCDTracker:Init()
	-- Setup the DB if needed
	KourCDTracker:SetupDB()

	-- Check if the current character has any cool downs
	-- KourCDTracker:AddonLoaded()

	local Frame = CreateFrame("Frame", nil, UIParent)

	-- Update the timers every second
	AceTimer:ScheduleRepeatingTimer(KourCDTracker.Tick, 1)

	-- Register event UNIT_SPELLCAST_SUCCEEDED
	-- Frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	Frame:RegisterEvent("TRADE_SKILL_UPDATE")

	-- Set event handler
	Frame:SetScript("OnEvent", KourCDTracker.HandleEvent)
end

function KourCDTracker:HandleEvent(event, ...)
	--[[for name, profs in pairs(CDTimers) do
		print(name .. " is in DB")
		if prof then
			for prof, skill in pairs(prof) do
				print(prof .. " - " .. skill)
			end
		end
	end]]

	if event == "TRADE_SKILL_UPDATE" then
		if KourCDTracker.Checked == 0 then
			KourCDTracker:CheckProfs()
			KourCDTracker.Checked = 1
		end
		KourCDTracker:TradeSkillUpdate()
	end

end

function KourCDTracker:TradeSkillUpdate()
	for prof, skillRank in pairs(CDTimers[KourCDTracker.Token]) do
		if skillRank >= KourCDTracker.SkillCheck[prof] then
			start, duration = GetSpellCooldown(KourCDTracker.SpellIDs[prof])
			if duration > 0 then
				print("Duration for " .. prof .. " is " .. start + duration - GetTime())
			else
				print("Duration for " .. prof .. " is DONE, use it NOW!")
			end
		end
	end
end

function KourCDTracker:CheckProfs()
	for skillIndex = 1, GetNumSkillLines() do
  		local prof, _, _, skillRank = GetSkillLineInfo(skillIndex)
  		if KourCDTracker.SpellIDs[prof] ~= nil then
  			CDTimers[KourCDTracker.Token][prof] = {}
  			CDTimers[KourCDTracker.Token][prof]["rank"] = skillRank
  			CDTimers[KourCDTracker.Token][prof]["cd"] = 0
  			if skillRank >= KourCDTracker.SkillCheck[prof] then
  				start, duration = GetSpellCooldown(KourCDTracker.SpellIDs[prof])
  				if duration > 0 then
  					serverTimeDone = start + duration - GetTime() + GetServerTime()
  					CDTimers[KourCDTracker.Token][prof]["cd"] = serverTimeDone
  				end
  			end
  		end
	end
end

function KourCDTracker:SpellCast(self, ... )
	-- body
	local unitID, _, spellID = ...
	if unitID ~= "player" then return end
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

function KourCDTracker:Tick( )
	-- body
end

function KourCDTracker:SetupDB()
	-- body
	if CDTimers == nil then
		CDTimers = {}
		CDTimers[KourCDTracker.Token] = {}
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