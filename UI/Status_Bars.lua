local addonName, addonTable = ...
local StatusGroup = CreateFrame("Frame", "MIH_StatusGroup", UIParent, "BackdropTemplate")

local HP_HEIGHT, MANA_HEIGHT, SPACING = 6, 16, 2
local dynamicWidth = 250

function addonTable.UpdateStatusBarsWidth(width)
    StatusGroup:SetWidth(width)
    if StatusGroup.hpCont then StatusGroup.hpCont:SetWidth(width) end
    if StatusGroup.mpCont then StatusGroup.mpCont:SetWidth(width) end
end

StatusGroup:SetSize(dynamicWidth, HP_HEIGHT + MANA_HEIGHT + SPACING)
StatusGroup:SetPoint("TOP", _G["MIH_ShortCDRow"], "BOTTOM", 0, -4)
StatusGroup:EnableMouse(false)

local function CreateBar(name, r, g, b, height)
    local barContainer = CreateFrame("Frame", name .. "Container", StatusGroup, "BackdropTemplate")
    barContainer:SetSize(dynamicWidth, height)
    barContainer:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    barContainer:SetBackdropColor(0.1, 0.1, 0.1, 0.7); barContainer:SetBackdropBorderColor(0, 0, 0, 1)

    local bar = CreateFrame("StatusBar", name, barContainer)
    bar:SetPoint("TOPLEFT", 1, -1); bar:SetPoint("BOTTOMRIGHT", -1, 1)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetStatusBarColor(r, g, b)

    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.text:SetFont(addonTable.MainFont, 12, "OUTLINE")
    bar.text:SetTextColor(1, 1, 1, 1)
    bar.text:SetPoint("CENTER", 0, 0)
    
    return barContainer, bar
end

StatusGroup.hpCont, healthBar = CreateBar("MIH_HealthBar", 0.1, 0.8, 0.1, HP_HEIGHT)
StatusGroup.hpCont:SetPoint("TOP", 0, 0)
StatusGroup.mpCont, manaBar = CreateBar("MIH_ManaBar", 0, 0.4, 1, MANA_HEIGHT)
StatusGroup.mpCont:SetPoint("TOP", StatusGroup.hpCont, "BOTTOM", 0, -SPACING)

StatusGroup:SetScript("OnUpdate", function()
    local hp, maxHp = UnitHealth("player"), UnitHealthMax("player")
    healthBar:SetMinMaxValues(0, maxHp > 0 and maxHp or 1); healthBar:SetValue(hp)
    local mp, maxMp = UnitPower("player"), UnitPowerMax("player")
    manaBar:SetMinMaxValues(0, maxMp > 0 and maxMp or 1); manaBar:SetValue(mp)
    manaBar.text:SetText(string.format("%d / %d", mp, maxMp - mp))
end)