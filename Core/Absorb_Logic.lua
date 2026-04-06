local addonName, addonTable = ...
local AbsorbLogic = CreateFrame("Frame")

addonTable.ActiveAbsorbs = {}

-- Database from your reference
-- Format: {school, basePoints, pointsPerLevel, baseLevel, maxLevel, spellLevel, healingMultiplier}
local absorbDb = {
    [11426] = {127, 437, 2.8, 40, 46, 40, 0.1}, -- Ice Barrier (Rank 1)
    [13031] = {127, 548, 3.2, 46, 52, 46, 0.1}, -- Ice Barrier (Rank 2)
    [13032] = {127, 677, 3.6, 52, 58, 52, 0.1}, -- Ice Barrier (Rank 3)
    [13033] = {127, 817, 4.0, 58, 64, 58, 0.1}, -- Ice Barrier (Rank 4)
    [1463]  = {1, 119, 0, 20, 0, 20, 0},        -- Mana Shield (Rank 1)
    [8494]  = {1, 209, 0, 28, 0, 28, 0},        -- Mana Shield (Rank 2)
    [8495]  = {1, 299, 0, 36, 0, 36, 0},        -- Mana Shield (Rank 3)
    [10191] = {1, 389, 0, 44, 0, 44, 0},        -- Mana Shield (Rank 4)
    [10192] = {1, 479, 0, 52, 0, 52, 0},        -- Mana Shield (Rank 5)
    [10193] = {1, 569, 0, 60, 0, 60, 0},        -- Mana Shield (Rank 6)
    [543]   = {4, 165, 0, 20, 0, 20, 0},        -- Fire Ward (Rank 1)
    [8457]  = {4, 289, 0, 30, 0, 30, 0},        -- Fire Ward (Rank 2)
    [8458]  = {4, 469, 0, 40, 0, 40, 0},        -- Fire Ward (Rank 3)
    [10223] = {4, 674, 0, 50, 0, 50, 0},        -- Fire Ward (Rank 4)
    [10225] = {4, 919, 0, 60, 0, 60, 0},        -- Fire Ward (Rank 5)
    [6143]  = {16, 164, 0, 22, 0, 22, 0},       -- Frost Ward (Rank 1)
    [8461]  = {16, 289, 0, 32, 0, 32, 0},       -- Frost Ward (Rank 2)
    [8462]  = {16, 469, 0, 42, 0, 42, 0},       -- Frost Ward (Rank 3)
    [10177] = {16, 674, 0, 52, 0, 52, 0},       -- Frost Ward (Rank 4)
    [28609] = {16, 919, 0, 60, 0, 60, 0},       -- Frost Ward (Rank 5)
}

local function CalculateInitialAbsorb(spellId)
    local info = absorbDb[spellId]
    if not info then return 0 end
    
    local level = UnitLevel("player")
    local base, perLevel, baseLevel, maxLevel, spellLevel, bonusMult = info[2], info[3], info[4], info[5], info[6], info[7]
    
    local levels = math.max(0, math.min(level, maxLevel > 0 and maxLevel or level) - baseLevel)
    local bonusHealing = GetSpellBonusHealing()
    local levelPenalty = math.min(1, 1 - (20 - spellLevel) * 0.03)

    return (base + (levels * perLevel)) + (bonusHealing * bonusMult * levelPenalty)
end

AbsorbLogic:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
AbsorbLogic:SetScript("OnEvent", function()
    local _, event, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, spellName, _, amount = CombatLogGetCurrentEventInfo()
    
    if destGUID ~= UnitGUID("player") then return end

    if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" then
        if absorbDb[spellId] then
            addonTable.ActiveAbsorbs[spellName] = CalculateInitialAbsorb(spellId)
        end
    elseif event == "SPELL_AURA_REMOVED" then
        addonTable.ActiveAbsorbs[spellName] = nil
    elseif event == "SPELL_ABSORBED" then
        -- CLEU index 17 or 20 contains the shield name depending on if it was a spell or melee hit
        local shieldName = select(20, CombatLogGetCurrentEventInfo()) or select(17, CombatLogGetCurrentEventInfo())
        local absorbAmount = select(22, CombatLogGetCurrentEventInfo()) or select(19, CombatLogGetCurrentEventInfo())
        
        if addonTable.ActiveAbsorbs[shieldName] then
            addonTable.ActiveAbsorbs[shieldName] = math.max(0, addonTable.ActiveAbsorbs[shieldName] - absorbAmount)
        end
    end
end)