local addonName, addonTable = ...
local Rotation = {}
addonTable.Rotation = Rotation

-- Constants & IDs
local AB_MAX_STACK_COST = 634
local MANA_EMERALD_REGEN = 2340
local MANA_POT_REGEN = 1800
local AB_SPELL_ID = 30451
local FB_SPELL_ID = 27072 -- Updated to highest rank
local MANA_EMERALD_ID = 22044
local MANA_POT_ID = 22832
local MANA_TIDE_ID = 16190
local ARCANE_POWER_ID = 12042

-- Textures
local TEX_AB = "Interface\\Icons\\Spell_Arcane_Blast"
local TEX_FB = "Interface\\Icons\\Spell_Frost_FrostBolt02"
local TEX_AP = "Interface\\Icons\\Spell_Arcane_MindMastery"

-- HELPER: Safe Aura Scanner
local function GetAuraCount(unit, spellID, filter)
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
        if not aura then break end 
        if aura.spellId == spellID then
            return aura.applications or 0
        end
    end
    return 0
end

-- Helper: Get Arcane Blast Stacks
local function GetABStacks()
    return GetAuraCount("player", AB_SPELL_ID, "HARMFUL")
end

-- Get Total Mana Per Second
function Rotation:GetManaPS()
    local _, castingRegen = GetManaRegen()
    local hasTide = GetAuraCount("player", MANA_TIDE_ID, "HELPFUL") > 0
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

    -- Arcane Power Tax logic
    local apTax = 1.0
    local cdInfo = C_Spell.GetSpellCooldown(ARCANE_POWER_ID)
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

    if state == "IDLE" then return {}, "IDLE" end

    -- Simulation Variables
    local simStacks = abStacks
    local simFBCount = 0
    local apSuggested = false

    -- Calculate Filler Goal
    local fbInfo = C_Spell.GetSpellInfo(FB_SPELL_ID)
    local abInfo = C_Spell.GetSpellInfo(AB_SPELL_ID)
    local fbCast = (fbInfo and fbInfo.castTime or 2500) / 1000
    local abCast = (abInfo and abInfo.castTime or 1500) / 1000
    local fillerGoal = ((3 * fbCast) + abCast < 8.2) and 4 or 3

    for i = 1, 5 do
        if state == "BURN" then
            table.insert(sequence, TEX_AB)

        elseif state == "STARTUP" then
            if simStacks < 3 then
                table.insert(sequence, TEX_AB)
                simStacks = simStacks + 1
            elseif not apSuggested then
                table.insert(sequence, TEX_AP)
                apSuggested = true
            else
                table.insert(sequence, TEX_AB)
            end

        elseif state == "CONSERVE" then
            -- Check if we are in the "Dropping" phase
            if simStacks >= 3 then
                table.insert(sequence, TEX_FB)
                simFBCount = simFBCount + 1
                -- Reset stacks after filler goal reached
                if simFBCount >= fillerGoal then
                    simStacks = 0
                    simFBCount = 0
                end
            else
                -- Building phase
                table.insert(sequence, TEX_AB)
                simStacks = simStacks + 1
            end
        end
    end

    return sequence, state
end