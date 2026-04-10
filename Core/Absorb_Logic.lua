local addonName, addonTable = ...
local AbsorbLogic = CreateFrame("Frame")

addonTable.ActiveAbsorbs = {}

-- Database from your reference
-- Format: {school, basePoints, pointsPerLevel, baseLevel, maxLevel, spellLevel, healingMultiplier}
local absorbDb = {
    -- Ice Barrier (School 127 = All)
    -- Format: {school, basePoints, pointsPerLevel, baseLevel, maxLevel, spellLevel, healingMultiplier}
    [11426] = {127, 437, 2.8, 40, 46, 40, 0.1}, -- Rank 1
    [13031] = {127, 548, 3.2, 46, 52, 46, 0.1}, -- Rank 2
    [13032] = {127, 677, 3.6, 52, 58, 52, 0.1}, -- Rank 3
    [13033] = {127, 817, 4.0, 58, 64, 58, 0.1}, -- Rank 4
    [27134] = {127, 925, 5.0, 66, 70, 66, 0.1}, -- Rank 5 (Learned Lvl 66, scales to 70)
    [33045] = {127, 1075, 0.0, 70, 70, 70, 0.1}, -- Rank 6 (Learned Lvl 70)

    -- Mana Shield (School 1 = Physical)
    -- TBC Patch 2.4.0: SP coefficient increased to 50%
    [1463]  = {1, 120, 0, 20, 20, 20, 0.5}, -- Rank 1
    [8494]  = {1, 210, 0, 28, 28, 28, 0.5}, -- Rank 2
    [8495]  = {1, 300, 0, 36, 36, 36, 0.5}, -- Rank 3
    [10191] = {1, 390, 0, 44, 44, 44, 0.5}, -- Rank 4
    [10192] = {1, 480, 0, 52, 52, 52, 0.5}, -- Rank 5
    [10193] = {1, 570, 0, 60, 60, 60, 0.5}, -- Rank 6
    [27131] = {1, 715, 0, 68, 70, 68, 0.5}, -- Rank 7 (TBC Learned Lvl 68)

    -- Fire Ward (School 4 = Fire)
    [543]   = {4, 165, 0, 20, 20, 20, 0.1}, -- Rank 1
    [8457]  = {4, 290, 0, 30, 30, 30, 0.1}, -- Rank 2
    [8458]  = {4, 470, 0, 40, 40, 40, 0.1}, -- Rank 3
    [10223] = {4, 675, 0, 50, 50, 50, 0.1}, -- Rank 4
    [10225] = {4, 875, 0, 60, 60, 60, 0.1}, -- Rank 5
    [27128] = {4, 1125, 0, 69, 70, 69, 0.1}, -- Rank 6 (TBC Learned Lvl 69)

    -- Frost Ward (School 16 = Frost)
    [6143]  = {16, 165, 0, 22, 22, 22, 0.1}, -- Rank 1
    [8461]  = {16, 290, 0, 32, 32, 32, 0.1}, -- Rank 2
    [8462]  = {16, 470, 0, 42, 42, 42, 0.1}, -- Rank 3
    [10177] = {16, 675, 0, 52, 52, 52, 0.1}, -- Rank 4
    [28609] = {16, 920, 0, 60, 60, 60, 0.1}, -- Rank 5
    [27129] = {16, 1220, 0, 70, 70, 70, 0.1}, -- Rank 6 (TBC Learned Lvl 70)
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