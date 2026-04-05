local addonName, addonTable = ...
local DamageSum = CreateFrame("Frame")

local totalDamage = 0
local lastCastTime = 0

-- Track all Mage AoE Spells
local AOE_SPELLS = {
    ["Arcane Explosion"] = true,
    ["Blizzard"] = true,
    ["Flamestrike"] = true,
}

local display = CreateFrame("Frame", "MIH_DamageSummaryFrame", UIParent)
display:SetSize(200, 50)
display:SetPoint("CENTER", 0, 50) 
display:Hide()

display.text = display:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
display.text:SetPoint("CENTER")
display.text:SetTextColor(1, 1, 1)

DamageSum:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
DamageSum:SetScript("OnEvent", function()
    -- Respect Config Toggle
    if MageItHappenDB and not MageItHappenDB.showDamageSummary then return end

    local _, subEvent, _, _, _, _, _, _, _, _, _, _, spellName, _, amount = CombatLogGetCurrentEventInfo()
    
    if subEvent == "SPELL_DAMAGE" and AOE_SPELLS[spellName] then
        local now = GetTime()
        
        -- Reset if more than 0.1s since last hit
        if now - lastCastTime > 0.1 then
            totalDamage = amount
        else
            totalDamage = totalDamage + amount
        end
        
        lastCastTime = now
        
        -- FIX: Explicitly cast the integer to a string
        display.text:SetText(tostring(totalDamage))
        
        display:Show()
        display:SetAlpha(1)
        
        C_Timer.After(1.5, function()
            if GetTime() - lastCastTime >= 1.5 then
                display:Hide()
            end
        end)
    end
end)

addonTable.DamageSum = DamageSum