local addonName, addonTable = ...
local combatTextFrame = CreateFrame("Frame", "MIH_CombatStatusFrame", UIParent)
combatTextFrame:SetSize(200, 20)

if _G["MageCustomCastbar"] then
    combatTextFrame:SetPoint("BOTTOM", _G["MageCustomCastbar"], "TOP", 0, 55)
else
    combatTextFrame:SetPoint("CENTER", 0, -50)
end

local statusText = combatTextFrame:CreateFontString(nil, "OVERLAY")
statusText:SetFont(addonTable.MainFont, 20, "OUTLINE")
statusText:SetPoint("CENTER")
statusText:Hide()

local function FlashText(msg, r, g, b)
    statusText:SetText(msg)
    statusText:SetTextColor(r, g, b)
    statusText:Show()
    C_Timer.After(1.5, function() statusText:Hide() end)
end

combatTextFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatTextFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatTextFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then FlashText("COMBAT", 1, 0, 0)
    elseif event == "PLAYER_REGEN_ENABLED" then FlashText("CLEAR", 0, 1, 0) end
end)