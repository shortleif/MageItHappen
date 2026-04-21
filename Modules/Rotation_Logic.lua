local addonName, addonTable = ...
local Rotation = {}
addonTable.Rotation = Rotation

-- Constants based on TBC Arcane Mechanics
local AB_MAX_STACK_COST = 634
local MANA_EMERALD_REGEN = 2340
local MANA_POT_REGEN = 1800
local AB_SPELL_ID = 30451

-- Updated Item ID for Mana Emerald
local MANA_EMERALD_ID = 22044
local MANA_POT_ID = 22832

-- Helper to check Arcane Blast stacks (DEBUFF on the player)
local function GetArcaneBlastStacks()
    local spellName = GetSpellInfo(AB_SPELL_ID)
    if not spellName then return 0 end
    
    for i = 1, 40 do
        local name, _, count = UnitDebuff("player", i)
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

-- Helper to check if an item is ready to use (Handles multiple API versions)
local function IsItemReady(itemID)
    if (GetItemCount(itemID) or 0) == 0 then return false end
    
    local startTime, duration
    if C_Container and C_Container.GetItemCooldown then
        startTime, duration = C_Container.GetItemCooldown(itemID)
    else
        startTime, duration = GetItemCooldown(itemID)
    end
    
    -- Handle table vs number return formats
    if type(startTime) == "table" then
        local t = startTime
        startTime = t.startTime
        duration = t.duration
    end
    
    return (not startTime or startTime == 0) or (GetTime() > (startTime + (duration or 0)))
end

-- Calculate current mana + available consumables (No Evocation)
function Rotation:GetTotalManaAvailable()
    local currentMana = UnitPower("player", 0)
    local extra = 0
    
    if IsItemReady(MANA_EMERALD_ID) then
        extra = extra + MANA_EMERALD_REGEN
    end
    
    if IsItemReady(MANA_POT_ID) then
        extra = extra + MANA_POT_REGEN
    end
    
    return currentMana + extra
end

function Rotation:GetManaState()
    -- Idle when out of combat
    if not UnitAffectingCombat("player") then return "IDLE" end

    local currentEffMana = self:GetTotalManaAvailable()
    local maxMana = UnitPowerMax("player", 0)
    
    local ttd = 999
    if addonTable.TTD_Core and addonTable.TTD_Core.GetCurrentTTD then
        ttd = addonTable.TTD_Core.GetCurrentTTD() or 999
    end

    -- STARTUP Phase: Immediately recommend Arcane Blast while TTD calculates
    if ttd >= 999 then return "STARTUP" end
    
    -- Safety for zero/negative TTD
    if ttd <= 0 then return "CONSERVE" end

    -- Estimate regen: ~2% max mana per 5s (Mage Armor)
    local regenPerSecond = (maxMana * 0.02) / 5 
    local totalManaIncome = currentEffMana + (regenPerSecond * ttd)

    local castTime = GetArcaneBlastCastTime()
    local numCasts = ttd / castTime
    local totalBurnCost = numCasts * AB_MAX_STACK_COST

    -- Decision Logic: Can we afford to spam AB until death?
    if totalManaIncome >= totalBurnCost then
        return "BURN"
    end

    return "CONSERVE"
end

local function GetArcaneBlastStacks()
    local spellName = GetSpellInfo(AB_SPELL_ID)
    if not spellName then return 0 end
    for i = 1, 40 do
        local name, _, _, count = UnitDebuff("player", i)
        if not name then break end
        if name == spellName then return count or 0 end
    end
    return 0
end

-- Generates a sequence of spell textures based on state
function Rotation:GetSequence()
    local state = self:GetManaState()
    local abStacks = GetArcaneBlastStacks()
    local sequence = {}

    local abTex = "Interface\\Icons\\Spell_Arcane_Blast"
    local fbTex = "Interface\\Icons\\Spell_Frost_FrostBolt02"
    local cdTex = "Interface\\Icons\\Spell_Arcane_MindMastery" -- Cooldowns

    if state == "STARTUP" then
        -- Sequence: AB until 3 stacks, then show CD reminder
        for i = 1, (3 - abStacks) do table.insert(sequence, abTex) end
        table.insert(sequence, cdTex)
        while #sequence < 5 do table.insert(sequence, abTex) end
        
    elseif state == "BURN" then
        -- Sequence: Pure AB spam
        for i = 1, 5 do table.insert(sequence, abTex) end
        
    elseif state == "CONSERVE" then
        -- Logic for 3xAB / 3xFB loop
        local currentStacks = abStacks
        for i = 1, 5 do
            if currentStacks < 3 then
                table.insert(sequence, abTex)
                currentStacks = currentStacks + 1
            else
                table.insert(sequence, fbTex)
                -- We assume after 3 FBs the stacks drop. 
                -- Simplified lookahead logic:
                if #sequence >= 3 then currentStacks = 0 end 
            end
        end
    end

    return sequence, state
end