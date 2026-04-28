local addonName, addonTable = ...
local Rotation = {}
addonTable.Rotation = Rotation

-- Constants & IDs
local AB_MAX_STACK_COST = 634
local MANA_EMERALD_REGEN = 2340
local MANA_POT_REGEN = 1800
local AB_SPELL_ID = 30451
local FB_SPELL_ID = 27072 
local MANA_EMERALD_ID = 22044
local MANA_POT_ID = 22832
local MANA_TIDE_ID = 16190
local AB_DEBUFF_DURATION = 8.2

-- Reliable scanner for modern engine that finds the debuff by name
local function GetABStacks()
    for i = 1, 40 do
        local aura = C_UnitAuras.GetDebuffDataByIndex("player", i)
        if not aura then break end
        if aura.name == "Arcane Blast" then
            return aura.applications or 0
        end
    end
    return 0
end

-- Get Total Mana Per Second
function Rotation:GetManaPS()
    local regenInfo = GetManaRegen()
    local castingRegen = regenInfo or 0
    
    local hasTide = false
    for i = 1, 40 do
        local aura = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not aura then break end
        if aura.name == "Mana Tide" then
            hasTide = true
            break
        end
    end
    
    local tideRegen = hasTide and (UnitPowerMax("player", 0) * 0.02) or 0
    return castingRegen + tideRegen
end

-- FIXED: Handles both table and number returns for Item Cooldowns
local function IsItemReady(itemID)
    if (GetItemCount(itemID) or 0) == 0 then return false end
    local cooldownInfo = C_Container.GetItemCooldown(itemID)
    local start, duration
    
    if type(cooldownInfo) == "table" then
        start = cooldownInfo.startTime
        duration = cooldownInfo.duration
    else
        -- Fallback for versions returning multiple values
        start, duration = C_Container.GetItemCooldown(itemID)
    end
    
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

    local totalMana = self:GetTotalManaAvailable()
    local mps = self:GetManaPS()
    local projectedMana = totalMana + (mps * ttd)

    -- FIXED: Handles both table and number returns for Spell Cooldowns
    local cdInfo = C_Spell.GetSpellCooldown(12042)
    local start, dur
    if type(cdInfo) == "table" then
        start, dur = cdInfo.startTime, cdInfo.duration
    else
        start, dur = C_Spell.GetSpellCooldown(12042)
    end
    
    local cdLeft = (start and start > 0) and (start + dur - GetTime()) or 0
    local apTax = (cdLeft < 20) and 1.3 or 1.0

    local spellInfo = C_Spell.GetSpellInfo(AB_SPELL_ID)
    local abCast = (spellInfo and spellInfo.castTime or 1500) / 1000
    local burnCost = (ttd / abCast) * AB_MAX_STACK_COST * apTax

    return (projectedMana >= burnCost) and "BURN" or "CONSERVE"
end

function Rotation:GetFrostboltGoal()
    local fbInfo = C_Spell.GetSpellInfo(FB_SPELL_ID)
    local abInfo = C_Spell.GetSpellInfo(AB_SPELL_ID)
    local fbCast = (fbInfo and fbInfo.castTime or 2500) / 1000
    local abCast = (abInfo and abInfo.castTime or 1500) / 1000
    
    if (3 * fbCast) + abCast < AB_DEBUFF_DURATION then
        return 4
    end
    return 3
end

function Rotation:GetRotationData()
    local state = self:GetManaState()
    local stacks = GetABStacks()
    local fbGoal = self:GetFrostboltGoal()
    
    local action = "WAITING"
    if state == "BURN" then
        action = "SPAM ARCANE BLAST"
    elseif state == "CONSERVE" then
        if stacks >= 3 then
            action = string.format("CAST %d x FROSTBOLT", fbGoal)
        else
            action = "BUILD STACKS (AB)"
        end
    elseif state == "STARTUP" then
        action = "OPENER"
    end
    
    return state, action, stacks, fbGoal
end