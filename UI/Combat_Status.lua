local addonName, addonTable = ...

-- 1. Create a frame to hold the flashing status text
local combatTextFrame = CreateFrame("Frame", "MIH_CombatStatusFrame", UIParent)
combatTextFrame:SetSize(200, 20)

-- 2. Anchor it "Just" on top of the Castbar
-- We use a small offset (2px) to keep it tight to the bar
if _G["MageCustomCastbar"] then
    combatTextFrame:SetPoint("BOTTOM", _G["MageCustomCastbar"], "TOP", 0, 2)
else
    -- Fallback position if the cast bar isn't found
    combatTextFrame:SetPoint("CENTER", 0, -50)
end

-- 3. Create the Text string
local statusText = combatTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
statusText:SetPoint("CENTER")
statusText:Hide()

-- 4. Logic to show the text and fade it out
local function FlashText(msg, r, g, b)
    statusText:SetText(msg)
    statusText:SetTextColor(r, g, b)
    statusText:Show()
    
    -- Hide after 1.5 seconds
    C_Timer.After(1.5, function() 
        statusText:Hide() 
    end)
end

-- 5. Event Handler
local function OnEvent(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        FlashText("COMBAT", 1, 1, 1) -- Bright Red
    elseif event == "PLAYER_REGEN_ENABLED" then
        FlashText("CLEAR", 1, 1, 1) -- Bright Green
    end
end

-- 6. Register Events
combatTextFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatTextFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatTextFrame:SetScript("OnEvent", OnEvent)