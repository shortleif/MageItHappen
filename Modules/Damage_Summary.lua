local addonName, addonTable = ...
local DamageSum = CreateFrame("Frame")

local totalDamage = 0
local lastCastTime = 0
local summaryActive = false

-- Create the Display Frame
local display = CreateFrame("Frame", "MIH_DamageSummaryFrame", UIParent)
display:SetSize(200, 50)
display:SetPoint("CENTER", 0, 50) -- Above the character
display:Hide()

display.text = display:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
display.text:SetPoint("CENTER")
display.text:SetTextColor(1, 1, 1) -- Pure White

DamageSum:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
DamageSum:SetScript("OnEvent", function()
    local _, subEvent, _, _, _, _, _, _, _, _, _, spellId, _, _, amount = CombatLogGetCurrentEventInfo()
    
    -- Filter for Arcane Explosion (SpellID 1449)
    if spellId == 1449 and subEvent == "SPELL_DAMAGE" then
        local now = GetTime()
        
        -- If this is a new cast (more than 0.1s since last hit), reset total
        if now - lastCastTime > 0.1 then
            totalDamage = amount
            summaryActive = true
        else
            totalDamage = totalDamage + amount
        end
        
        lastCastTime = now
        
        -- Update UI
        display.text:SetText(totalDamage)
        display:Show()
        display:SetAlpha(1)
        
        -- Simple Fade-out logic
        C_Timer.After(1.5, function()
            if GetTime() - lastCastTime >= 1.5 then
                display:Hide()
            end
        end)
    end
end)

addonTable.DamageSum = DamageSum