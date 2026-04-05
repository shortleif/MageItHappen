local addonName, addonTable = ...
local DamageSum = CreateFrame("Frame")
local totalDamage, lastCastTime = 0, 0
local AOE_SPELLS = { ["Arcane Explosion"] = true, ["Blizzard"] = true, ["Flamestrike"] = true }

local display = CreateFrame("Frame", "MIH_DamageSummaryFrame", UIParent)
display:SetSize(200, 50); display:SetPoint("CENTER", 0, 50); display:Hide()

-- LEGIBLE FONT & TEXT INDEX FIX
display.text = display:CreateFontString(nil, "OVERLAY")
display.text:SetFont(addonTable.MainFont, 28, "OUTLINE")
display.text:SetPoint("CENTER"); display.text:SetTextColor(1, 1, 1)

DamageSum:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
DamageSum:SetScript("OnEvent", function()
    if MageItHappenDB and not MageItHappenDB.showDamageSummary then return end
    local _, subEvent, _, _, _, _, _, _, _, _, _, _, spellName, _, amount = CombatLogGetCurrentEventInfo()
    if subEvent == "SPELL_DAMAGE" and AOE_SPELLS[spellName] then
        local now = GetTime()
        totalDamage = (now - lastCastTime > 0.1) and amount or (totalDamage + amount)
        lastCastTime = now
        display.text:SetText(tostring(totalDamage))
        display:Show(); display:SetAlpha(1)
        C_Timer.After(1.5, function() if GetTime() - lastCastTime >= 1.5 then display:Hide() end end)
    end
end)