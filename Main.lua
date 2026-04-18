local addonName, addonTable = ...

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
            "MissingBuffs", "Procs", "AbsorbDisplay", "RotationTracker"
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
