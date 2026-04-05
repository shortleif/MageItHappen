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

-- CRITICAL FIX: Ensure the group and its children NEVER catch the mouse
-- This ensures buttons behind/under the bars remain clickable.
StatusGroup:EnableMouse(false)

local function CreateBar(name, r, g, b, height)
    local barContainer = CreateFrame("Frame", name .. "Container", StatusGroup, "BackdropTemplate")
    barContainer:SetSize(dynamicWidth, height)
    barContainer:EnableMouse(false) -- Disable mouse interaction

    barContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", 
        edgeFile = "Interface\\Buttons\\WHITE8X8", 
        edgeSize = 1
    })
    barContainer:SetBackdropColor(0.1, 0.1, 0.1, 0.7) 
    barContainer:SetBackdropBorderColor(0, 0, 0, 1)

    local bar = CreateFrame("StatusBar", name, barContainer)
    bar:SetPoint("TOPLEFT", 1, -1) 
    bar:SetPoint("BOTTOMRIGHT", -1, 1)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetStatusBarColor(r, g, b)
    bar:EnableMouse(false) -- Disable mouse interaction
    
    return barContainer, bar
end

local hpCont, healthBar = CreateBar("MIH_HealthBar", 0.1, 0.8, 0.1, HP_HEIGHT)
hpCont:SetPoint("TOP", 0, 0)

local mpCont, manaBar = CreateBar("MIH_ManaBar", 0, 0.4, 1, MANA_HEIGHT)
mpCont:SetPoint("TOP", hpCont, "BOTTOM", 0, -SPACING)

manaBar.text = manaBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
manaBar.text:SetPoint("CENTER", 0, 0)

StatusGroup:SetScript("OnUpdate", function(self)
    local mp, maxMp = UnitPower("player"), UnitPowerMax("player")
    manaBar:SetMinMaxValues(0, maxMp)
    manaBar:SetValue(mp)
    manaBar.text:SetText(string.format("%d / %d", mp, maxMp - mp))
    
    healthBar:SetMinMaxValues(0, UnitHealthMax("player"))
    healthBar:SetValue(UnitHealth("player"))
end)