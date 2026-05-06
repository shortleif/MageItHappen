local addonName, addonTable = ...
local Rotation = {}

-- IDs for items to calculate Total Available Mana
local MANA_EMERALD_ID = 22044
local SUPER_MANA_POTION_ID = 22832

-- Helper: Get current Cast Time in seconds
local function GetSpellCastTime(spellName)
    local spellInfo = C_Spell.GetSpellInfo(spellName)
    if spellInfo and spellInfo.castTime then
        -- C_Spell returns cast time in milliseconds, convert to seconds
        return spellInfo.castTime / 1000 
    end
    return 2.5 -- Fallback
end

-- Helper: Get Arcane Blast Mana Cost
local function GetABManaCost()
    local costs = C_Spell.GetSpellPowerCost("Arcane Blast")
    if costs and costs[1] then
        return costs[1].cost
    end
    return 200 -- Fallback baseline
end

-- Helper: Calculate Total Available Mana
local function GetTotalAvailableMana()
    local currentMana = UnitPower("player", Enum.PowerType.Mana)
    
    -- Fix: Use the standard global GetItemCount function
    local emeraldMana = (GetItemCount(MANA_EMERALD_ID) > 0) and 2400 or 0
    local potionMana = (GetItemCount(SUPER_MANA_POTION_ID) > 0) and 2400 or 0
    
    return currentMana + emeraldMana + potionMana
end

-- Helper: Scan for Arcane Blast debuff on the player
local function GetABDebuffInfo()
    local i = 1
    while true do
        local aura = C_UnitAuras.GetDebuffDataByIndex("player", i, "HARMFUL")
        if not aura then break end
        
        if aura.name == "Arcane Blast" then
            local timeLeft = aura.expirationTime - GetTime()
            return aura.applications or 1, timeLeft
        end
        i = i + 1
    end
    return 0, 0
end

function Rotation.GetState()
    local ttd = addonTable.TTD_Core.GetCurrentTTD()
    local totalMana = GetTotalAvailableMana()
    
    local abCastTime = GetSpellCastTime("Arcane Blast")
    local fbCastTime = GetSpellCastTime("Frostbolt")
    local abManaCost = GetABManaCost()
    
    -- 1. Mana State Determination (Burn Phase check)
    local manaNeededForBurn = ttd * (abManaCost / abCastTime)
    
    if totalMana >= manaNeededForBurn and ttd < 999 then
        return "BURN", "Arcane Blast", "BURN: SPAM AB", 1, 0, 0 -- Red
    end
    
    -- 2. Conserve Phase Logic
    local stacks, timeLeft = GetABDebuffInfo()
    
    if stacks < 3 then
        return "BUILD", "Arcane Blast", "BUILDING AB", 0, 0, 0 -- Black
    else
        -- Stacks are >= 3. Can we "Handoff"?
        if timeLeft <= abCastTime then
            return "HANDOFF", "Arcane Blast", "HANDOFF AB", 0.5, 0, 0.8 -- Purple/Blue
        else
            -- We must fill time with Frostbolt
            return "FILL", "Frostbolt", string.format("FB FILL (%.1fs)", timeLeft), 0, 0.3, 0 -- Dark Green
        end
    end
end

-- Export to shared table
addonTable.Rotation = Rotation