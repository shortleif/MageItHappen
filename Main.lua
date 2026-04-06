local addonName, addonTable = ...

-- NEW: Centralized legibility font and path
local FONT_SIZE_LARGE = 16

local ttdFrame = CreateFrame("Frame", "MyTTDVisualFrame", UIParent, "BackdropTemplate")
ttdFrame:SetSize(150, 40)
ttdFrame:SetPoint("CENTER", 0, -100) 
ttdFrame:SetMovable(true)
ttdFrame:EnableMouse(true)
ttdFrame:RegisterForDrag("LeftButton")
ttdFrame:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 5, edgeSize = 1})
ttdFrame:SetBackdropColor(0, 0, 0, 0.5)

ttdFrame:SetScript("OnDragStart", ttdFrame.StartMoving)
ttdFrame:SetScript("OnDragStop", ttdFrame.StopMovingOrSizing)

-- FIX: Applied custom font and outline
local ttdText = ttdFrame:CreateFontString(nil, "OVERLAY")
ttdText:SetFont(addonTable.MainFont, FONT_SIZE_LARGE, "OUTLINE")
ttdText:SetPoint("CENTER")
ttdText:SetTextColor(1, 1, 1, 1)

-- 3. State Tracking
local isInBossEncounter = false

-- 4. Event Registration
ttdFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
ttdFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
ttdFrame:RegisterEvent("ENCOUNTER_START")
ttdFrame:RegisterEvent("ENCOUNTER_END")

-- 5. Visibility Handler
ttdFrame:SetScript("OnEvent", function(self, event, ...)
    -- Track Boss Encounter State
    if event == "ENCOUNTER_START" then
        isInBossEncounter = true
    elseif event == "ENCOUNTER_END" then
        isInBossEncounter = false
    end

    -- Check Database Settings
    local db = MageItHappenDB
    if not db or not db.showTTD then 
        self:Hide()
        return 
    end

    -- Handle Trigger Events
    if event == "PLAYER_REGEN_DISABLED" or event == "ENCOUNTER_START" then
        if db.showOnlyInEncounter then
            -- Only show if we are actually fighting a boss
            if isInBossEncounter then self:Show() else self:Hide() end
        else
            -- Show for any combat (trash or bosses)
            self:Show()
        end
    elseif event == "PLAYER_REGEN_ENABLED" or event == "ENCOUNTER_END" then
        -- Hide when combat or boss encounter ends
        if not UnitAffectingCombat("player") then
            self:Hide()
        end
    end
end)

-- 6. The Update Loop
ttdFrame:SetScript("OnUpdate", function(self, elapsed)
    local TTD = addonTable.TTD_Core
    local Sync = addonTable.SyncLogic
    if not TTD or not Sync then return end

    -- Update TTD math
    TTD.OnUpdate()
    local currentTTD = TTD.GetCurrentTTD()
    
    -- Update Display Text
    if not UnitExists("target") or UnitIsDead("target") then
        ttdText:SetText("No Target") 
    elseif currentTTD >= 999 then
        ttdText:SetText("Calculating...")
    else
        ttdText:SetText(string.format("TTD: %ds", math.floor(currentTTD + 0.5)))
    end

    -- Evaluate Cooldown/Trinket Sync Logic
    -- Fetch Spell Cooldowns (Adjust IDs for TBC Anniversary)
    local apInfo = C_Spell.GetSpellCooldown(12042)
    local ap_CD = (apInfo and apInfo.startTime > 0) and (apInfo.startTime + apInfo.duration - GetTime()) or 0
    
    local ivInfo = C_Spell.GetSpellCooldown(12472)
    local iv_CD = (ivInfo and ivInfo.startTime > 0) and (ivInfo.startTime + ivInfo.duration - GetTime()) or 0
    
    -- Run the "Glow" check in the background
    Sync.EvaluateTrinketGlow(13, ap_CD, iv_CD)
    Sync.EvaluateTrinketGlow(14, ap_CD, iv_CD)
end)

-- Initial State Check
if not UnitAffectingCombat("player") then 
    ttdFrame:Hide() 
end