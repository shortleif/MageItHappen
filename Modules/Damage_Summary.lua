local addonName, addonTable = ...
local DamageSum = CreateFrame("Frame")
local totalDamage, lastCastTime = 0, 0

-- Updated spell list with both spelling variations for compatibility
local AOE_SPELLS = { 
    ["Arcane Explosion"] = true, 
    ["Blizzard"] = true, 
    ["Flamestrike"] = true, 
    ["Cone of Cold"] = true, 
    ["Blast Wave"] = true 
}

local display = CreateFrame("Frame", "MIH_DamageSummaryFrame", UIParent)
display:SetSize(200, 50); display:SetPoint("CENTER", 0, 50); display:Hide()

display.text = display:CreateFontString(nil, "OVERLAY")
display.text:SetFont(addonTable.MainFont, 32, "OUTLINE")
display.text:SetTextColor(1, 1, 1, 1)
display.text:SetPoint("CENTER")

-- Cache variable for the player's unique ID
local playerGUID

DamageSum:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
DamageSum:SetScript("OnEvent", function()
    if MageItHappenDB and not MageItHappenDB.showDamageSummary then return end
    
    -- Initialize or verify player GUID
    playerGUID = playerGUID or UnitGUID("player")
    
    -- Capture sourceGUID (4th parameter) to filter the combat log
    local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, _, spellName, _, amount = CombatLogGetCurrentEventInfo()
    
    -- FIXED: Only process if the source of the damage is YOUR character
    if sourceGUID == playerGUID and subEvent == "SPELL_DAMAGE" and AOE_SPELLS[spellName] then
        local now = GetTime()
        
        -- Reset total if it's a new cast (gap > 0.1s), otherwise add to total
        totalDamage = (now - lastCastTime > 0.1) and amount or (totalDamage + amount)
        lastCastTime = now
        
        -- Explicitly cast to string for the UI text
        display.text:SetText(tostring(totalDamage))
        display:Show(); display:SetAlpha(1)
        
        -- Auto-hide logic
        C_Timer.After(1.5, function() 
            if GetTime() - lastCastTime >= 1.5 then display:Hide() end 
        end)
    end
end)