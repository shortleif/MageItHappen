local addonName, addonTable = ...
local StatusGroup = CreateFrame("Frame", "MIH_StatusGroup", UIParent, "BackdropTemplate")

-- Configuration
local HP_HEIGHT = 6
local MANA_HEIGHT = 16 
local SPACING = 2
local dynamicWidth = addonTable.shortRowWidth or 250

-- Position the group
StatusGroup:SetSize(dynamicWidth, HP_HEIGHT + MANA_HEIGHT + SPACING)
StatusGroup:SetPoint("TOP", _G["MIH_ShortCDRow"], "BOTTOM", 0, -4)

local function CreateBar(name, r, g, b, height)
    -- Create the container frame for the border
    local barContainer = CreateFrame("Frame", name .. "Container", StatusGroup, "BackdropTemplate")
    barContainer:SetSize(dynamicWidth, height)
    
    -- Apply the exact same black border look as the Castbar
    barContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", 
        edgeFile = "Interface\\Buttons\\WHITE8X8", 
        edgeSize = 1
    })
    barContainer:SetBackdropColor(0.1, 0.1, 0.1, 0.7) -- Same dark background
    barContainer:SetBackdropBorderColor(0, 0, 0, 1)    -- Solid black 1px border

    -- Create the actual moving StatusBar inside the container
    local bar = CreateFrame("StatusBar", name, barContainer)
    bar:SetPoint("TOPLEFT", 1, -1) -- Inset by 1px to show the border
    bar:SetPoint("BOTTOMRIGHT", -1, 1)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetStatusBarColor(r, g, b)
    
    return barContainer, bar
end

-- 1. Create the Health Bar
local hpCont, healthBar = CreateBar("MIH_HealthBar", 0.1, 0.8, 0.1, HP_HEIGHT)
hpCont:SetPoint("TOP", 0, 0)

-- 2. Create the Mana Bar
local mpCont, manaBar = CreateBar("MIH_ManaBar", 0, 0.4, 1, MANA_HEIGHT)
mpCont:SetPoint("TOP", hpCont, "BOTTOM", 0, -SPACING)

-- 3. Add Mana Text
manaBar.text = manaBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
manaBar.text:SetPoint("CENTER", 0, 0)

-- Update Logic
StatusGroup:SetScript("OnUpdate", function(self)
    local hp, maxHp = UnitHealth("player"), UnitHealthMax("player")
    healthBar:SetMinMaxValues(0, maxHp)
    healthBar:SetValue(hp)
    
    local mp, maxMp = UnitPower("player"), UnitPowerMax("player")
    local missingMana = maxMp - mp
    
    manaBar:SetMinMaxValues(0, maxMp)
    manaBar:SetValue(mp)
    
    manaBar.text:SetText(string.format("%d / %d", mp, missingMana))
end)