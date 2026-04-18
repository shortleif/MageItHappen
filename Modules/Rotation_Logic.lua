local addonName, addonTable = ...
local Rotation = {}
addonTable.Rotation = Rotation

-- Constants based on TBC Arcane Mechanics
local AB_MAX_STACK_COST = 634
local MANA_EMERALD_REGEN = 2400
local MANA_POT_REGEN = 2200
local AB_SPELL_ID = 30451

-- Helper to check Arcane Blast stacks (DEBUFF on the player)
local function GetArcaneBlastStacks()
    local spellName = GetSpellInfo(AB_SPELL_ID)
    if not spellName then return 0 end
    
    for i = 1, 40 do
        -- Use local variables to avoid leaking into other addons
        local name, _, _, count = UnitDebuff("player", i)
        if not name then break end
        if name == spellName then
            return count or 0
        end
    end
    return 0
end

-- Helper to get current cast time for mana budget calculations
local function GetArcaneBlastCastTime()
    local _, _, _, castTime = GetSpellInfo(AB_SPELL_ID)
    return (castTime or 1500) / 1000
end

function Rotation:GetManaState()
    -- Hide tracker when out of combat to prevent nil/idle errors
    if not UnitAffectingCombat("player") then return "IDLE" end

    local currentMana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    
    -- Corrected reference to your TTD_Core module
    local ttd = 999
    if addonTable.TTD_Core and addonTable.TTD_Core.GetCurrentTTD then
        ttd = addonTable.TTD_Core.GetCurrentTTD() or 999
    end

    -- Fight start/invalid TTD handling
    if ttd >= 999 or ttd <= 0 then return "CONSERVE" end

    -- 1. Calculate Mana Income
    local regenPerSecond = (maxMana * 0.02) / 5 
    local totalManaIncome = currentMana + (regenPerSecond * ttd)

    -- Consumable check using your tracker
    if addonTable.ConsumableTracker and addonTable.ConsumableTracker.IsReady then
        if addonTable.ConsumableTracker:IsReady("Mana Emerald") then
            totalManaIncome = totalManaIncome + MANA_EMERALD_REGEN
        end
        if addonTable.ConsumableTracker:IsReady("Super Mana Potion") then
            totalManaIncome = totalManaIncome + MANA_POT_REGEN
        end
    end

    -- 2. Calculate Burn Cost
    local castTime = GetArcaneBlastCastTime()
    local numCasts = ttd / castTime
    local totalBurnCost = numCasts * AB_MAX_STACK_COST

    -- 3. Decision Logic
    if totalManaIncome >= totalBurnCost then
        return "BURN"
    end

    return "CONSERVE"
end

function Rotation:GetRecommendedAction()
    local state = self:GetManaState()
    
    if state == "IDLE" then
        return nil, nil
    end

    local abStacks = GetArcaneBlastStacks()

    if state == "BURN" then
        return "Interface\\Icons\\Spell_Arcane_Blast", "|cffff0000BURN|r"
    else
        -- Conserve Phase logic
        if abStacks >= 3 then
            return "Interface\\Icons\\Spell_Frost_FrostBolt02", "|cff00ffffCONSERVE|r\n(Drop Stacks)"
        else
            return "Interface\\Icons\\Spell_Arcane_Blast", "|cff00ff00CONSERVE|r\n(Build AB)"
        end
    end
end