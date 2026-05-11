local addonName, addonTable = ...

local DebugFrame = CreateFrame("Frame", "MIH_DebugFrame", UIParent, "BackdropTemplate")
DebugFrame:SetSize(220, 160)
DebugFrame:SetPoint("RIGHT", -50, 0)
DebugFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1
})
DebugFrame:SetBackdropColor(0, 0, 0, 0.8)
DebugFrame:SetBackdropBorderColor(1, 0.8, 0, 1)
DebugFrame:SetMovable(true)
DebugFrame:EnableMouse(true)
DebugFrame:RegisterForDrag("LeftButton")
DebugFrame:SetScript("OnDragStart", DebugFrame.StartMoving)
DebugFrame:SetScript("OnDragStop", DebugFrame.StopMovingOrSizing)
DebugFrame:Hide()

local debugTitle = DebugFrame:CreateFontString(nil, "OVERLAY")
debugTitle:SetFont(addonTable.MainFont or "Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
debugTitle:SetPoint("TOP", 0, -5)
debugTitle:SetText("|cff00ccffMIH Debug Info|r")

local debugText = DebugFrame:CreateFontString(nil, "OVERLAY")
debugText:SetFont(addonTable.MainFont or "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
debugText:SetPoint("TOPLEFT", 10, -25)
debugText:SetJustifyH("LEFT")

local Launcher = CreateFrame("Frame")
Launcher:RegisterEvent("ADDON_LOADED")
Launcher:RegisterEvent("PLAYER_LOGIN")

Launcher:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize SavedVariables table if missing
        if not MageItHappenDB then MageItHappenDB = {} end
    elseif event == "PLAYER_LOGIN" then
        print("|cff00ccffMageItHappen:|r Specialized Arcane Assistant Loaded.")
        
        -- Run Initializations
        if addonTable.TTD_UI then addonTable.TTD_UI:Initialize() end
        
        local modules = {
            "StatusBars", "AuraBars", "UnitFrames", "Castbar",
            "ABTracker", "ConsumableTracker", "CDTracker",
            "MissingBuffs", "Procs", "AbsorbDisplay", "RotationTracker", "IntellectChecker"
        }
        for _, name in ipairs(modules) do
            local m = addonTable[name]
            if m then
                if m.InitializeUI then m:InitializeUI() end
                if m.Initialize then m:Initialize() end
            end
        end
    end
end)

Launcher:SetScript("OnUpdate", function(self, elapsed)
    -- 1. Update Core Math
    if addonTable.TTD_Core then
        addonTable.TTD_Core.OnUpdate()
        local currentTTD = addonTable.TTD_Core.GetCurrentTTD()
        if addonTable.TTD_UI then addonTable.TTD_UI:UpdateDisplay(currentTTD) end
    end

    -- 2. Update Rotation
    if addonTable.RotationTracker and addonTable.RotationTracker.UpdateDisplay then
        addonTable.RotationTracker:UpdateDisplay()
    end

    -- 3. Update Sync/Glows
    if addonTable.SyncLogic then
        local ap_CD = 0 -- Logic to fetch spell CDs as per original Main.lua
        addonTable.SyncLogic.EvaluateTrinketGlow(13, ap_CD, 0)
        addonTable.SyncLogic.EvaluateTrinketGlow(14, ap_CD, 0)
    end

    -- 4. Update Debug Display
    if MageItHappenDB and MageItHappenDB.debugMode then
        DebugFrame:Show()
        local di = addonTable.DebugInfo or {}
        local str = string.format(
            "Current Mana: %d\nEmerald: %d\nPotion: %d\nEvocation: %d\nVT Regen (Expected): %d\n\nTotal Available: %d", 
            di.currentMana or 0,
            di.emeraldMana or 0,
            di.potionMana or 0,
            di.evoMana or 0,
            di.vtMana or 0,
            di.totalMana or 0
        )
        debugText:SetText(str)
    else
        DebugFrame:Hide()
    end
end)

--[[ Update Trinket Glows
if Sync then
    local apInfo = C_Spell.GetSpellCooldown(12042)
    local ap_CD = (apInfo and apInfo.startTime > 0) and (apInfo.startTime + apInfo.duration - GetTime()) or 0
    local ivInfo = C_Spell.GetSpellCooldown(12472)
    local iv_CD = (ivInfo and ivInfo.startTime > 0) and (ivInfo.startTime + ivInfo.duration - GetTime()) or 0
    
    Sync.EvaluateTrinketGlow(13, ap_CD, iv_CD)
    Sync.EvaluateTrinketGlow(14, ap_CD, iv_CD)
end ]]--
