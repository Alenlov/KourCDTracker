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
KourCDTracker.frame = {} 

function KourCDTracker:Init()
	-- Setup the DB if needed
	KourCDTracker:SetupDB()
	KourCDTracker:SetupFrame()
	-- Check if the current character has any cool downs
	-- KourCDTracker:AddonLoaded()

	local frame = CreateFrame("Frame", nil, UIParent)

	-- Update the timers every second
	AceTimer:ScheduleRepeatingTimer(KourCDTracker.Tick, 1)

	-- Register event UNIT_SPELLCAST_SUCCEEDED
	-- Frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	frame:RegisterEvent("TRADE_SKILL_UPDATE")

	-- Set event handler
	frame:SetScript("OnEvent", KourCDTracker.HandleEvent)

	
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
	for prof, charInfo in pairs(CDTimers[KourCDTracker.Token]) do
		if charInfo["rank"] >= KourCDTracker.SkillCheck[prof] then
			start, duration = GetSpellCooldown(KourCDTracker.SpellIDs[prof])
			if duration > 0 then
				serverTimeDone = start + duration - GetTime() + GetServerTime()
				CDTimers[KourCDTracker.Token][prof]["cd"] = serverTimeDone
			else
				CDTimers[KourCDTracker.Token][prof]["cd"] = 0
			end	
			--[[if duration > 0 then
				print("Duration for " .. prof .. " is " .. start + duration - GetTime())
			else
				print("Duration for " .. prof .. " is DONE, use it NOW!")
			end]]

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
				else
					CDTimers[KourCDTracker.Token][prof]["cd"] = 0
				end
			end
		end
	end
end

function KourCDTracker:Tick( )
	-- body
	local text = ""
	local anyReady = false
	for char, storedInfo in pairs(CDTimers) do
		if storedInfo ~= {} then
			for prof, charInfo in pairs(storedInfo) do
				if charInfo["rank"] then
					if charInfo["rank"] >= KourCDTracker.SkillCheck[prof] then
						timeToFinished = charInfo["cd"] - GetServerTime()
						charName, server = strsplit("-", char)
						text = text .. charName .. " : " .. prof
						if timeToFinished > 0 then
							days = math.floor(timeToFinished/(60*60*24))
							hours = math.floor(timeToFinished/(60*60) - days*24)
							mins = math.floor(timeToFinished/60 - hours*60 - days*24*60)
							secs = math.floor(timeToFinished - mins*60 - hours*60*60 - days*24*60*60)
							doneString = string.format("%01.f:%02.f:%02.f:%02.f",days, hours, mins, secs)
							text = text .." - " .. timeToFinished
						else
							text = text .. " is ready now!"
							anyReady = true
						end
						text = text .. "\n"
					end
				end
			end
		end
	end
	KourCDTracker.frame.infoText:SetText(text)
	KourCDTracker.frame.infoText:SetHeight(KourCDTracker.frame.infoText:GetStringHeight())
	KourCDTracker.frame.infoText:SetJustifyH("LEFT")
	KourCDTracker.frame.infoText:SetJustifyV("TOP")
	if anyReady then
		KourCDTracker.frame.header:SetTextColor(0,1,0)
	else
		KourCDTracker.frame.header:SetTextColor(1,0,0)
	end
end

function KourCDTracker:SetupFrame( )
	-- body
	local f1 = CreateFrame("Frame", "KourCDTrackerFrame", UIParent)
	f1:SetMovable(CDTimersConfig.Movable)
	f1:EnableMouse(true)
	f1:RegisterForDrag("LeftButton")
	f1:SetScript("OnDragStart", f1.StartMoving)
	f1:SetScript("OnDragStop", f1.StopMovingOrSizing)
	f1:SetPoint("CENTER")
	f1:SetWidth(64)
	f1:SetHeight(64)
	f1.header = f1:CreateFontString(nil, "ARTWORK")
	f1.header:SetFont("Fonts\\ARIALN.ttf", 16, "OUTLINE")
	f1.header:SetPoint("LEFT")
	f1.header:SetText("Kour CD Tracker")
	headerHeight = f1.header:GetStringHeight()
	f1.infoText = f1:CreateFontString(nil,"HIGHLIGHT")
	f1.infoText:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
	f1.infoText:SetPoint("TOPLEFT",0,-headerHeight-25)
	f1.infoText:SetText("Kour CD Tracker")
	f1:Show()
	KourCDTracker.frame = f1
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
		CDTimersConfig.Movable = true
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