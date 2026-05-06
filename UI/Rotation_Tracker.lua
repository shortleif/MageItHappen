local addonName, addonTable = ...
local Tracker = CreateFrame("Frame", "MageItHappen_Tracker", MIH_StatusGroup, "BackdropTemplate")

-- Frame Setup
Tracker:SetSize(120, 120)
Tracker:SetPoint("RIGHT", _G["MIH_StatusGroup"], "LEFT", -15, 10)
Tracker:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

-- Icon Texture
Tracker.Icon = Tracker:CreateTexture(nil, "ARTWORK")
Tracker.Icon:SetSize(64, 64)
Tracker.Icon:SetPoint("TOP", 0, -15)

-- Text Label
Tracker.Text = Tracker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Tracker.Text:SetPoint("BOTTOM", 0, 15)
-- Use the custom font from your Init.lua if it exists
if addonTable.MainFont then
    Tracker.Text:SetFont(addonTable.MainFont, 14, "OUTLINE")
end

-- Initial State
Tracker:Hide()
Tracker.isActive = false

-- Update Loop
local function OnUpdate(self, elapsed)
    if not self.isActive then return end
    
    -- Fetch the state from the Logic engine
    local state, spellName, text, r, g, b = addonTable.Rotation.GetState()
    
    -- Update Colors
    self:SetBackdropColor(r, g, b, 0.8)
    
    -- Update Text
    self.Text:SetText(text)
    
    -- Update Icon dynamically using modern C_Spell API
    local spellInfo = C_Spell.GetSpellInfo(spellName)
    if spellInfo and spellInfo.iconID then
        self.Icon:SetTexture(spellInfo.iconID)
    end
end

Tracker:SetScript("OnUpdate", OnUpdate)

-- Event Handling to show/hide the frame
Tracker:RegisterEvent("PLAYER_REGEN_DISABLED")
Tracker:RegisterEvent("PLAYER_REGEN_ENABLED")
Tracker:RegisterEvent("PLAYER_TARGET_CHANGED")

Tracker:SetScript("OnEvent", function(self, event)
    -- 1. Check if we have a valid, living enemy target
    local hasTarget = UnitExists("target")
    local canAttack = hasTarget and UnitCanAttack("player", "target")
    local isAlive = hasTarget and not UnitIsDead("target")
    
    -- 2. Determine combat state, accounting for API delays
    local inCombat = InCombatLockdown() or UnitAffectingCombat("player")
    
    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true -- Force true if we just entered combat
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false -- Force false if we just left combat
    end
    
    -- 3. Show or Hide
    if inCombat and canAttack and isAlive then
        self.isActive = true
        self:Show()
    else
        self.isActive = false
        self:Hide()
        
        -- Optional: Reset color so it doesn't flash the previous state on next target
        self:SetBackdropColor(0, 0, 0, 0.8)
    end
end)

addonTable.RotationTracker = Tracker