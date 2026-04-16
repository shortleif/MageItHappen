local addonName, addonTable = ...

local BOX_SIZE = 12
local SPACING = 4
local NUM_BOXES = 4

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

-- UPDATED: Squares now hide when the buff is found (isUp == true)
local function UpdateBox(box, isUp)
    if isUp then
        box:Hide() -- Hide if the buff is active
    else
        box:Show() -- Show (Red) if the buff is missing
    end
end

local function ScanConsumables()
    if CHECK_RAID_ONLY and not IsInRaid() then
        ConsumableTracker:Hide()
        return
    end
    ConsumableTracker:Show()

    local hasFood, hasBattle, hasGuardian, hasWeapon = false, false, false, false
    
    -- Weapon Enhancement check
    local hasMainHandEnchant = GetWeaponEnchantInfo()
    if hasMainHandEnchant then hasWeapon = true end

    -- Scan Player Auras for TBC Consumables
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end

        if name == "Well Fed" then hasFood = true end

        local isFlask = false
        -- TBC Flask Spell IDs
        if spellId == 28521 or spellId == 28520 or spellId == 17628 then 
            isFlask = true
        end

        if isFlask then
            hasBattle = true
            hasGuardian = true
        else
            -- Mage specific elixir detection
            if name:find("Adept") or name:find("Major Firepower") or name:find("Spellpower") then
                hasBattle = true
            elseif name:find("Draenic Wisdom") or name:find("Mageblood") or name:find("Mighty Thoughts") then
                hasGuardian = true
            end
        end
    end

    UpdateBox(boxes.food, hasFood)
    UpdateBox(boxes.battle, hasBattle)
    UpdateBox(boxes.guardian, hasGuardian)
    UpdateBox(boxes.weapon, hasWeapon)
end

ConsumableTracker:RegisterEvent("UNIT_AURA")
ConsumableTracker:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
ConsumableTracker:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ConsumableTracker:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" and unit ~= "player" then return end
    ScanConsumables()
end)

ScanConsumables()