local addonName, addonTable = ...

-- 1. Create the UI Window for the Text
local ttdFrame = CreateFrame("Frame", "MyTTDVisualFrame", UIParent, "BackdropTemplate")
ttdFrame:SetSize(150, 40)
ttdFrame:SetPoint("CENTER", 0, -100) 
ttdFrame:SetMovable(true)
ttdFrame:EnableMouse(true)
ttdFrame:RegisterForDrag("LeftButton")

-- Add a temporary background so you can see it while dragging
ttdFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true, tileSize = 5, edgeSize = 1,
})
ttdFrame:SetBackdropColor(0, 0, 0, 0.5) -- Semi-transparent black

ttdFrame:SetScript("OnDragStart", ttdFrame.StartMoving)
ttdFrame:SetScript("OnDragStop", ttdFrame.StopMovingOrSizing)

-- 2. Create the White Text string
local ttdText = ttdFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ttdText:SetPoint("CENTER")
ttdText:SetTextColor(1, 1, 1, 1) 
ttdText:SetText("TTD: Ready") -- Initial text

-- 3. The Event Handler (The Logic Glue)
ttdFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
ttdFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
ttdFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

ttdFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        self:Show()
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:Hide()
    end
end)

-- 4. The Update Loop
ttdFrame:SetScript("OnUpdate", function(self, elapsed)
    -- We use the shared table to get our modules
    local TTD = addonTable.TTD_Core
    local Sync = addonTable.SyncLogic
    
    -- If files aren't loaded correctly, this stops the error
    if not TTD or not Sync then 
        ttdText:SetText("ERR: Modules Missing")
        return 
    end

    -- Run the TTD math
    TTD.OnUpdate()
    
    local currentTTD = TTD.GetCurrentTTD()
    
    -- Update Display
    if not UnitExists("target") or UnitIsDead("target") then
        ttdText:SetText("No Target") 
    elseif currentTTD >= 999 then
        ttdText:SetText("Calculating...")
    else
        ttdText:SetText(string.format("TTD: %ds", math.floor(currentTTD + 0.5)))
    end

    -- Background Trinket Logic
    local apInfo = C_Spell.GetSpellCooldown(12042)
    local ap_CD = (apInfo and apInfo.startTime > 0) and (apInfo.startTime + apInfo.duration - GetTime()) or 0
    
    local ivInfo = C_Spell.GetSpellCooldown(12472)
    local iv_CD = (ivInfo and ivInfo.startTime > 0) and (ivInfo.startTime + ivInfo.duration - GetTime()) or 0
    
    local shouldGlow = Sync.EvaluateTrinketGlow(13, ap_CD, iv_CD)
end)

-- Start hidden (Only if we aren't already in combat)
if not UnitAffectingCombat("player") then
    ttdFrame:Hide()
end