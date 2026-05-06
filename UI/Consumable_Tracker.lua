local addonName, addonTable = ...

local BOX_SIZE = 12
local SPACING = 4
local NUM_BOXES = 4
local LOW_DURATION_THRESHOLD = 300 -- 5 minutes

local TOTAL_HEIGHT = (BOX_SIZE * NUM_BOXES) + (SPACING * (NUM_BOXES - 1))

-- Buff Logic Definitions
local CHECK_RAID_ONLY = true

local ConsumableTracker = CreateFrame("Frame", "MIH_ConsumableTracker", UIParent, "BackdropTemplate")
ConsumableTracker:SetSize(BOX_SIZE, TOTAL_HEIGHT) 

-- Anchored to MageCustomCastbar
ConsumableTracker:SetPoint("RIGHT", _G["MageCustomCastbar"] or UIParent, "LEFT", -5, -42)

local function CreateStatusBox(parent, index)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(BOX_SIZE, BOX_SIZE)
    f:SetPoint("TOP", 0, -((index - 1) * (BOX_SIZE + SPACING)))
    f:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.8, 0.2, 0.2, 0.8) -- Default Red
    f:SetBackdropBorderColor(0, 0, 0, 1)
    return f
end

local boxes = {
    food = CreateStatusBox(ConsumableTracker, 1),
    battle = CreateStatusBox(ConsumableTracker, 2),
    guardian = CreateStatusBox(ConsumableTracker, 3),
    weapon = CreateStatusBox(ConsumableTracker, 4),
}

-- UPDATED: Now handles visibility and color based on duration
local function UpdateBox(box, isUp, isLow)
    if isUp and not isLow then
        box:Hide() -- Hide if buff is found and duration is healthy
    else
        box:Show() 
        if isLow then
            box:SetBackdropColor(1, 1, 0, 0.8) -- Yellow if low duration[cite: 1]
        else
            box:SetBackdropColor(0.8, 0.2, 0.2, 0.8) -- Red if missing
        end
    end
end

local function ScanConsumables()
    -- LUA Protocol: Use local variables for function returns in conditionals[cite: 1]
    local IsInRaid = IsInRaid()
    if CHECK_RAID_ONLY and not IsInRaid then
        ConsumableTracker:Hide()
        return
    end
    ConsumableTracker:Show()

    local hasFood, foodLow = false, false
    local hasBattle, battleLow = false, false
    local hasGuardian, guardianLow = false, false
    local hasWeapon, weaponLow = false, false
    
    local currentTime = GetTime()

    -- Weapon Enhancement check
    local hasMainHandEnchant, mainHandExpiration = GetWeaponEnchantInfo()
    if hasMainHandEnchant then 
        hasWeapon = true 
        local weaponRem = mainHandExpiration / 1000 -- Convert ms to seconds
        if weaponRem < LOW_DURATION_THRESHOLD then
            weaponLow = true
        end
    end

    -- Scan Player Auras for TBC Consumables
    for i = 1, 40 do
        local name, _, _, _, _, expirationTime, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end

        local remaining = 0
        if expirationTime and expirationTime > 0 then
            remaining = expirationTime - currentTime
        end

        -- Check Food
        if name == "Well Fed" then 
            hasFood = true 
            if remaining > 0 and remaining < LOW_DURATION_THRESHOLD then foodLow = true end
        end

        -- Check Flasks (Covers both Battle and Guardian)
        local isFlask = false
        if spellId == 28521 or spellId == 28520 or spellId == 17628 then 
            isFlask = true
        end

        if isFlask then
            hasBattle = true
            hasGuardian = true
            if remaining > 0 and remaining < LOW_DURATION_THRESHOLD then
                battleLow = true
                guardianLow = true
            end
        else
            -- Mage specific elixir detection
            if name:find("Adept") or name:find("Major Firepower") or name:find("Spellpower") then
                hasBattle = true
                if remaining > 0 and remaining < LOW_DURATION_THRESHOLD then battleLow = true end
            elseif name:find("Draenic Wisdom") or name:find("Mageblood") or name:find("Mighty Thoughts") then
                hasGuardian = true
                if remaining > 0 and remaining < LOW_DURATION_THRESHOLD then guardianLow = true end
            end
        end
    end

    UpdateBox(boxes.food, hasFood, foodLow)
    UpdateBox(boxes.battle, hasBattle, battleLow)
    UpdateBox(boxes.guardian, hasGuardian, guardianLow)
    UpdateBox(boxes.weapon, hasWeapon, weaponLow)
end

ConsumableTracker:RegisterEvent("UNIT_AURA")
ConsumableTracker:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
ConsumableTracker:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ConsumableTracker:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" and unit ~= "player" then return end
    ScanConsumables()
end)

ScanConsumables()