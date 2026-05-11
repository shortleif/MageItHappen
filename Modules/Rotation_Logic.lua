local addonName, addonTable = ...
local Rotation = {}
addonTable.Rotation = Rotation
addonTable.DebugInfo = {}



-- Global flag to track if we are in the initial phase of combat for mana calculations
local isInInitialCombatPhase = true

-- Function to reset the initial combat phase flag, to be called when combat starts
local function ResetInitialCombatPhase()
    isInInitialCombatPhase = true
end

-- Helper to update the initial combat phase flag based on TTD
local function UpdateCombatPhase(ttd)
    -- If TTD is very high (e.g., > 990) or we are still in the initial phase and combat just started, stay in initial phase.
    -- Transition out of initial phase if TTD drops significantly or if combat just ended and restarted.
    if ttd > 990 then
        isInInitialCombatPhase = true
    elseif isInInitialCombatPhase and ttd < 990 then
        -- Transition out of initial phase if TTD drops below a threshold
        isInInitialCombatPhase = false
    end
    -- If combat just ended and restarted, isInInitialCombatPhase should be reset to true by ResetInitialCombatPhase()
end

-- VT Mana Return Rolling Average
local vtManaReturnHistory = {}

local function AddVtManaReturnData(manaReturned)
    local currentTime = GetTime()
    table.insert(vtManaReturnHistory, { timestamp = currentTime, mana = manaReturned })
    
    -- Prune old data outside the rolling window
    local vtRollingAverageWindow = (MageItHappenDB and MageItHappenDB.vtRollingAverageWindow) or 30
    local cutoffTime = currentTime - vtRollingAverageWindow
    local i = 1
    while i <= #vtManaReturnHistory do
        if vtManaReturnHistory[i].timestamp < cutoffTime then
            table.remove(vtManaReturnHistory, i)
        else
            i = i + 1
        end
    end
end

local function CalculateVtRollingAverage()
    if #vtManaReturnHistory == 0 then return 0 end
    
    local totalMana = 0
    for _, data in ipairs(vtManaReturnHistory) do
        totalMana = totalMana + data.mana
    end
    
    return totalMana / #vtManaReturnHistory
end

-- Constant Variables
local MANA_EMERALD_REGEN = 2340
local MANA_POT_REGEN = 1800
local AB_SPELL_ID = 30451
local AB_DEBUFF_ID = 36032 -- Correct TBC Debuff ID
local FB_SPELL_ID = 27072 
local MANA_EMERALD_ID = 22044
local MANA_POT_ID = 22832
local MANA_TIDE_ID = 16190
local ARCANE_POWER_ID = 12042
local AB_DEBUFF_DURATION = 8.2
local EVOCATION_SPELL_ID = 12051
local SHADOWFORM_ID = 15473

-- Helper: Check if a Shadow Priest is in the party
local function HasShadowPriest()
    -- VT is party-wide in TBC. Check self and party members.
    local units = {"player", "party1", "party2", "party3", "party4"}
    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            for i = 1, 40 do
                local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, "HELPFUL")
                if not name then break end
                if spellId == SHADOWFORM_ID or name == "Shadowform" then
                    return true
                end
            end
        end
    end
    return false
end

-- Helper: Get current Cast Time in seconds
local function GetSpellCastTime(spellName)
    local spellInfo = C_Spell.GetSpellInfo(spellName)
    if spellInfo and spellInfo.castTime then
        return spellInfo.castTime / 1000 
    end
    return 2.5 
end

-- Helper: Get Arcane Blast Mana Cost
local function GetABManaCost()
    local costs = C_Spell.GetSpellPowerCost("Arcane Blast")
    if costs and costs[1] then
        return costs[1].cost
    end
    return 200 
end

-- Helper: Calculate Total Available Mana
local function GetTotalAvailableMana()
    local currentMana = UnitPower("player", Enum.PowerType.Mana)
    local maxMana = UnitPowerMax("player", Enum.PowerType.Mana)
    
    local emeraldCount = GetItemCount(MANA_EMERALD_ID)
    local potionCount = GetItemCount(MANA_POT_ID)
    
    local emeraldMana = (emeraldCount > 0) and MANA_EMERALD_REGEN or 0
    local potionMana = (potionCount > 0) and MANA_POT_REGEN or 0
    
    local total = currentMana + emeraldMana + potionMana
    
    local start, duration = GetSpellCooldown(EVOCATION_SPELL_ID)
    local isEvoReady = false
    if not start or start == 0 or duration <= 1.5 then isEvoReady = true end

    local ttd = 0
    if addonTable.TTD_Core then 
        ttd = addonTable.TTD_Core.GetCurrentTTD() 
    end
    
    local evoMana = 0
    if isEvoReady then
        evoMana = maxMana * 0.60
        -- Include in total if the fight is long enough to channel, or if out of combat (ttd == 0)
        if ttd > 8 or ttd == 0 then
            total = total + evoMana
        end
    end
    
    addonTable.DebugInfo.currentMana = currentMana
    addonTable.DebugInfo.emeraldMana = emeraldMana
    addonTable.DebugInfo.potionMana = potionMana
    addonTable.DebugInfo.evoMana = evoMana
    
    return total
end

-- Helper: Scan for Arcane Blast debuff using provided TBC Logic
local function GetABDebuffInfo()
    local currentTime = GetTime()
    for i = 1, 40 do
        local n, _, c, _, _, e, _, _, _, spellId = UnitAura("player", i, "HARMFUL")
        if not n then break end
        
        if spellId == AB_DEBUFF_ID then
            -- Fallback count to 1 if the API returns 0 for the first stack
            local count = c
            if count == 0 then count = 1 end
            
            local timeLeft = 0
            if e and e > 0 then
                timeLeft = e - currentTime
            end
            
            return count, timeLeft
        end
    end
    return 0, 0
end

-- Visibility Logic for UI
function Rotation.ShouldShow()
    local db = MageItHappenDB
    if not db then return true end

    local hideOutside = db.rotationHideOutsideEncounter
    local showSpec1 = db.rotationShowInSpec1
    local showSpec2 = db.rotationShowInSpec2
    
    local inEncounter = IsEncounterInProgress()
    local activeSpec = GetActiveTalentGroup()
    
    local specAllowed = false
    if activeSpec == 1 and showSpec1 then specAllowed = true end
    if activeSpec == 2 and showSpec2 then specAllowed = true end
    
    local finalShow = true
    if not specAllowed then finalShow = false end
    if hideOutside and not inEncounter then finalShow = false end
    
    return finalShow
end

function Rotation.GetState()
    local ttd = 0
    if addonTable.TTD_Core then
        ttd = addonTable.TTD_Core.GetCurrentTTD()
    end
    
    -- Update combat phase status
    UpdateCombatPhase(ttd)
    
    local totalMana = GetTotalAvailableMana()
    local abCastTime = GetSpellCastTime("Arcane Blast")
    local abManaCost = GetABManaCost()
    local vtMana = 0
    
    -- 1. Initial Combat Phase Mana Calculation
    if isInInitialCombatPhase then
        -- Use static mana return for VT during the initial phase
        if MageItHappenDB.trackVT and ttd > 0 and HasShadowPriest() then
            local vtMP5 = MageItHappenDB.vtMP5 or 200
            -- Add a single tick's worth of mana for the initial phase, and log it for the rolling average later.
            vtMana = vtMP5 / 5 * 1 
            totalMana = totalMana + vtMana
        end
    else
        -- Use rolling average for VT mana return after initial phase
        if MageItHappenDB.trackVT and ttd > 0 and HasShadowPriest() then
            vtMana = CalculateVtRollingAverage()
            totalMana = totalMana + vtMana
        end
    end
    
    addonTable.DebugInfo.vtMana = vtMana
    addonTable.DebugInfo.totalMana = totalMana
    
    -- 0. Evocation Emergency Check (moved after mana calculation to use updated totalMana)
    local currentMana = UnitPower("player", Enum.PowerType.Mana)
    local maxMana = UnitPowerMax("player", Enum.PowerType.Mana)
    local manaPercent = (currentMana / maxMana) * 100
    
    local start, duration = GetSpellCooldown(EVOCATION_SPELL_ID)
    local isEvoReady = false
    if not start or start == 0 or duration <= 1.5 then isEvoReady = true end
    
    -- Check if Evocation is ready and mana is critically low, AND we are not in the initial combat phase (to avoid interrupting early phase power spikes)
    if isEvoReady and ttd > 8 and not isInInitialCombatPhase then
        -- Prioritize Evocation if mana is critically low and it won't disrupt the initial burn
        if manaPercent < 15 then
            return "EVO", "Evocation", "LOW MANA", 0, 1, 1 
        end
    end
    
    -- 1. Mana State Determination (Burn Phase check)
    local manaNeededForBurn = ttd * (abManaCost / abCastTime)
    
    if totalMana >= manaNeededForBurn and ttd < 999 then
        return "BURN", "Arcane Blast", "BURN: SPAM AB", 1, 0, 0 
    end
    
    -- 2. Conserve Phase Logic
    local stacks, timeLeft = GetABDebuffInfo()
    
    if stacks < 3 then
        return "BUILD", "Arcane Blast", "BUILDING AB", 0, 0, 0 
    else
        -- Stacks are >= 3. Can we "Handoff"?
        if timeLeft <= abCastTime then
            return "HANDOFF", "Arcane Blast", "HANDOFF AB", 0.5, 0, 0.8 
        else
            -- We must fill time with Frostbolt
            return "FILL", "Frostbolt", string.format("FB FILL (%.1fs)", timeLeft), 0, 0.3, 0 
        end
    end
end

-- Need to find where combat starts to call ResetInitialCombatPhase()
-- For now, assuming that combat start is implicitly handled by ttd > 990 in UpdateCombatPhase.
-- If a more direct combat start event is available, ResetInitialCombatPhase() should be called there.