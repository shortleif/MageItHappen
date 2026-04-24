local addonName, addonTable = ...
local Rotation = {}
addonTable.Rotation = Rotation

-- Constants & IDs
local AB_MAX_STACK_COST = 634
local MANA_EMERALD_REGEN = 2340
local MANA_POT_REGEN = 1800
local AB_SPELL_ID = 30451
local FB_SPELL_ID = 116
local MANA_EMERALD_ID = 22044
local MANA_POT_ID = 22832
local MANA_TIDE_ID = 16190

-- HELPER: Safe Aura Scanner (Modern API)
local function GetAuraCount(unit, spellID, filter)
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
        if not aura then break end 
        if aura.spellId == spellID then
            return aura.applications or 0
        end
    end
    return nil
end

-- Helper: Get Arcane Blast Stacks
local function GetABStacks()
    return GetAuraCount("player", AB_SPELL_ID, "HARMFUL") or 0
end

-- Get Total Mana Per Second (Modern API)
function Rotation:GetManaPS()
    local _, castingRegen = GetManaRegen()
    local hasTide = GetAuraCount("player", MANA_TIDE_ID, "HELPFUL")
    local tideRegen = hasTide and (UnitPowerMax("player", 0) * 0.02) or 0
    return (castingRegen or 0) + tideRegen
end

-- Helper: Item Ready Check
local function IsItemReady(itemID)
    if (GetItemCount(itemID) or 0) == 0 then return false end
    local cooldownInfo = C_Container.GetItemCooldown(itemID)
    local start = (type(cooldownInfo) == "table") and cooldownInfo.startTime or cooldownInfo
    local duration = (type(cooldownInfo) == "table") and cooldownInfo.duration or 0
    return (not start or start == 0) or (GetTime() > (start + duration))
end

function Rotation:GetTotalManaAvailable()
    local current = UnitPower("player", 0)
    local extra = 0
    if IsItemReady(MANA_EMERALD_ID) then extra = extra + MANA_EMERALD_REGEN end
    if IsItemReady(MANA_POT_ID) then extra = extra + MANA_POT_REGEN end
    return current + extra
end

function Rotation:GetManaState()
    local isHostile = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
    if not UnitAffectingCombat("player") or not isHostile then return "IDLE" end

    local ttd = addonTable.TTD_Core and addonTable.TTD_Core.GetCurrentTTD() or 999
    if ttd >= 999 then return "STARTUP" end
    if ttd < 30 then return "BURN" end 

    local totalMana = self:GetTotalManaAvailable()
    local mps = self:GetManaPS()
    local projectedMana = totalMana + (mps * ttd)

    -- Arcane Power Tax
    local apTax = 1.0
    local cdInfo = C_Spell.GetSpellCooldown(12042)
    local start = (type(cdInfo) == "table") and cdInfo.startTime or cdInfo
    local dur = (type(cdInfo) == "table") and cdInfo.duration or 180
    local cdLeft = (start and start > 0) and (start + dur - GetTime()) or 0
    if cdLeft < 20 then apTax = 1.3 end

    local spellInfo = C_Spell.GetSpellInfo(AB_SPELL_ID)
    local abCast = (spellInfo and spellInfo.castTime or 1500) / 1000
    local burnCost = (ttd / abCast) * AB_MAX_STACK_COST * apTax

    return (projectedMana >= burnCost) and "BURN" or "CONSERVE"
end

function Rotation:GetSequence()
    local state = self:GetManaState()
    local abStacks = GetABStacks()
    local sequence = {}
    
    local abTex = "Interface\\Icons\\Spell_Arcane_Blast"
    local fbTex = "Interface\\Icons\\Spell_Frost_FrostBolt02"
    local cdTex = "Interface\\Icons\\Spell_Arcane_MindMastery"

    if state == "IDLE" then return {}, "IDLE" end

    if state == "STARTUP" then
        for i = 1, (3 - abStacks) do table.insert(sequence, abTex) end
        table.insert(sequence, cdTex)
        while #sequence < 5 do table.insert(sequence, abTex) end
    elseif state == "BURN" then
        for i = 1, 5 do table.insert(sequence, abTex) end
    elseif state == "CONSERVE" then
        local fbInfo = C_Spell.GetSpellInfo(FB_SPELL_ID)
        local abInfo = C_Spell.GetSpellInfo(AB_SPELL_ID)
        local fbCast = (fbInfo and fbInfo.castTime or 2500) / 1000
        local abCast = (abInfo and abInfo.castTime or 1500) / 1000
        
        -- Dynamic Filler Goal: 3 or 4 Frostbolts based on 8.2s window
        local fillerGoal = ((3 * fbCast) + abCast < 8.2) and 4 or 3
        
        -- Simulation Logic
        local simStacks = abStacks
        local fbAdded = 0
        -- If we already have 3 stacks, we are currently in the "Dropping" phase
        local mode = (simStacks >= 3) and "DROPPING" or "BUILDING"

        for i = 1, 5 do
            if mode == "BUILDING" then
                table.insert(sequence, abTex)
                simStacks = simStacks + 1
                if simStacks >= 3 then
                    mode = "DROPPING"
                    fbAdded = 0
                end
            else -- mode == "DROPPING"
                table.insert(sequence, fbTex)
                fbAdded = fbAdded + 1
                if fbAdded >= fillerGoal then
                    mode = "BUILDING"
                    simStacks = 0
                end
            end
        end
    end
    return sequence, state
end