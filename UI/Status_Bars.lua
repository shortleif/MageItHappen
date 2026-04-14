local addonName, addonTable = ...
-- Converted to Button for player frame functionality
local StatusGroup = CreateFrame("Button", "MIH_StatusGroup", UIParent, "SecureUnitButtonTemplate, BackdropTemplate")

-- Secure attributes for player frame
StatusGroup:SetAttribute("unit", "player")
StatusGroup:RegisterForClicks("AnyUp")
StatusGroup:SetAttribute("*type1", "target")
StatusGroup:SetAttribute("*type2", "togglemenu")

-- HP_HEIGHT 12 for the requested "player frame" feel
local HP_HEIGHT, MANA_HEIGHT, SPACING = 12, 16, 2
local dynamicWidth = 250

function addonTable.UpdateStatusBarsWidth(width)
    StatusGroup:SetWidth(width)
    if StatusGroup.hpCont then StatusGroup.hpCont:SetWidth(width) end
    if StatusGroup.mpCont then StatusGroup.mpCont:SetWidth(width) end
end

StatusGroup:SetSize(dynamicWidth, HP_HEIGHT + MANA_HEIGHT + SPACING)
StatusGroup:SetPoint("TOP", _G["MIH_ShortCDRow"], "BOTTOM", 0, -4)

-- Utility Icon Factory for Food/Drink
local function CreateUtilityIcon(parent, texture)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(18, 18) -- Same height as castbar
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexture(texture)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    b:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    b:SetBackdropBorderColor(0, 0, 0, 1)
    
    b:SetScript("OnEnter", function(self)
        if self.auraIndex then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetUnitAura("player", self.auraIndex, "HELPFUL")
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:Hide()
    return b
end

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

-- Setup Icons in the Castbar space
StatusGroup.foodIcon = CreateUtilityIcon(StatusGroup, "Interface\\Icons\\Spell_Misc_Food")
StatusGroup.drinkIcon = CreateUtilityIcon(StatusGroup, "Interface\\Icons\\Spell_Misc_Drink")

-- FIXED: Position food at the start (left) and drink at the end (right)
if _G["MageCustomCastbar"] then
    StatusGroup.foodIcon:SetPoint("LEFT", _G["MageCustomCastbar"], "LEFT", 0, 0)
    StatusGroup.drinkIcon:SetPoint("RIGHT", _G["MageCustomCastbar"], "RIGHT", 0, 0)
else
    StatusGroup.foodIcon:SetPoint("BOTTOMLEFT", StatusGroup.hpCont, "TOPLEFT", 0, 18)
    StatusGroup.drinkIcon:SetPoint("BOTTOMRIGHT", StatusGroup.hpCont, "TOPRIGHT", 0, 18)
end

StatusGroup:SetScript("OnUpdate", function()
    -- Health & Class Color Logic
    local hp, maxHp = UnitHealth("player"), UnitHealthMax("player")
    healthBar:SetMinMaxValues(0, maxHp > 0 and maxHp or 1); healthBar:SetValue(hp)
    
    local _, class = UnitClass("player")
    local color = class and RAID_CLASS_COLORS[class]
    if color then healthBar:SetStatusBarColor(color.r, color.g, color.b) end
    healthBar.text:SetText("")

    -- Mana Logic
    local mp, maxMp = UnitPower("player"), UnitPowerMax("player")
    manaBar:SetMinMaxValues(0, maxMp > 0 and maxMp or 1); manaBar:SetValue(mp)
    manaBar.text:SetText(string.format("%d / %d", mp, maxMp - mp))

    -- Monitor Eating/Drinking
    StatusGroup.foodIcon:Hide()
    StatusGroup.drinkIcon:Hide()
    for i = 1, 40 do
        local name = UnitAura("player", i, "HELPFUL")
        if not name then break end
        if name == "Food" then
            StatusGroup.foodIcon.auraIndex = i
            StatusGroup.foodIcon:Show()
        elseif name == "Drink" then
            StatusGroup.drinkIcon.auraIndex = i
            StatusGroup.drinkIcon:Show()
        end
    end
end)

-- Hover tooltip for player frame
StatusGroup:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetUnit("player")
    GameTooltip:Show()
end)
StatusGroup:SetScript("OnLeave", function() GameTooltip:Hide() end)