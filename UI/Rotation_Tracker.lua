local addonName, addonTable = ...
local Tracker = CreateFrame("Frame", "MageItHappen_Tracker", MIH_StatusGroup, "BackdropTemplate")

-- Frame Setup
Tracker:SetSize(120, 120)
Tracker:SetPoint("RIGHT", _G["MIH_StatusGroup"], "LEFT", -40, 10)
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

if addonTable.MainFont then
    Tracker.Text:SetFont(addonTable.MainFont, 14, "OUTLINE")
end

-- Initial State
Tracker:Hide()
Tracker.isActive = false

-- Update Loop
local function OnUpdate(self, elapsed)
    if not self.isActive then return end
    
    -- Throttle execution to 20 fps to save CPU processing power
    self.timer = (self.timer or 0) + elapsed
    if self.timer < 0.05 then return end
    self.timer = 0

    -- Fetch the state from the Logic engine
    local state, spellName, text, r, g, b = addonTable.Rotation.GetState()
    
    -- Update Colors
    self:SetBackdropColor(r, g, b, 0.8)
    
    -- Update Text
    self.Text:SetText(text)
    
    -- Update Icon dynamically
    local spellInfo = C_Spell.GetSpellInfo(spellName)
    if spellInfo and spellInfo.iconID then
        self.Icon:SetTexture(spellInfo.iconID)
    end
end

Tracker:SetScript("OnUpdate", OnUpdate)

-- Function to handle complex visibility checks per protocol
local function RefreshVisibility(self, event)
    -- 1. Gather Target State
    local hasTarget = UnitExists("target")
    local canAttack = false
    local isAlive = false
    
    if hasTarget then
        canAttack = UnitCanAttack("player", "target")
        isAlive = not UnitIsDead("target")
    end
    
    -- 2. Gather Combat/Config State
    local inCombat = InCombatLockdown() or UnitAffectingCombat("player")
    if event == "PLAYER_REGEN_DISABLED" then inCombat = true end
    if event == "PLAYER_REGEN_ENABLED" then inCombat = false end

    -- 3. Check Logic Engine for Config-based visibility (Spec/Encounter)[cite: 1]
    local logicAllows = false
    if addonTable.Rotation and addonTable.Rotation.ShouldShow then
        logicAllows = addonTable.Rotation.ShouldShow()
    end

    -- 4. Final Boolean Logic
    local shouldBeActive = false
    if logicAllows and inCombat and canAttack and isAlive then
        shouldBeActive = true
    end

    -- 5. Apply State
    if shouldBeActive then
        self.isActive = true
        self:Show()
    else
        self.isActive = false
        self:Hide()
        self:SetBackdropColor(0, 0, 0, 0.8)
    end
end

-- Event Handling
Tracker:RegisterEvent("PLAYER_REGEN_DISABLED")
Tracker:RegisterEvent("PLAYER_REGEN_ENABLED")
Tracker:RegisterEvent("PLAYER_TARGET_CHANGED")
Tracker:RegisterEvent("PLAYER_TALENT_UPDATE") -- Added for spec swaps[cite: 1]
Tracker:RegisterEvent("ENCOUNTER_START")      -- Added for encounter toggle[cite: 1]
Tracker:RegisterEvent("ENCOUNTER_END")

Tracker:SetScript("OnEvent", function(self, event)
    RefreshVisibility(self, event)
end)

addonTable.RotationTracker = Tracker