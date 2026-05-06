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
local healthBar, manaBar

local function FormatValue(val)
    if not val then return "0" end
    if val >= 1000000 then return string.format("%.1fm", val / 1000000)
    elseif val >= 1000 then return string.format("%.1fk", val / 1000)
    else return tostring(math.floor(val)) end
end

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
    b:SetSize(25, 25) -- Same height as castbar
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

-- Haste Tracker Display
StatusGroup.hasteText = manaBar:CreateFontString(nil, "OVERLAY")
StatusGroup.hasteText:SetFont(addonTable.MainFont, 12, "OUTLINE")
StatusGroup.hasteText:SetPoint("RIGHT", StatusGroup.mpCont, "RIGHT", -6, 80)
StatusGroup.hasteText:Hide()

-- Setup Icons in the Castbar space
StatusGroup.foodIcon = CreateUtilityIcon(StatusGroup, "Interface\\Icons\\Spell_Misc_Food")
StatusGroup.drinkIcon = CreateUtilityIcon(StatusGroup, "Interface\\Icons\\Inv_drink_18")

if _G["MageCustomCastbar"] then
    StatusGroup.foodIcon:SetPoint("LEFT", _G["MageCustomCastbar"], "LEFT", 0, 0)
    StatusGroup.drinkIcon:SetPoint("RIGHT", _G["MageCustomCastbar"], "RIGHT", 0, 0)
else
    StatusGroup.foodIcon:SetPoint("BOTTOMLEFT", StatusGroup.hpCont, "TOPLEFT", 0, 18)
    StatusGroup.drinkIcon:SetPoint("BOTTOMRIGHT", StatusGroup.hpCont, "TOPRIGHT", 0, 18)
end

-- ==========================================
-- NEW: Frost Elemental Tracker Frame & Text
-- ==========================================
StatusGroup.eleIcon = CreateFrame("Frame", nil, StatusGroup, "BackdropTemplate")
StatusGroup.eleIcon:SetSize(25, 25)
-- Position it to the right of the mana bar (adjust X and Y to your liking!)
StatusGroup.eleIcon:SetPoint("LEFT", StatusGroup.mpCont, "RIGHT", 10, 0) 
StatusGroup.eleIcon:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
StatusGroup.eleIcon:SetBackdropBorderColor(0, 0, 0, 1)

StatusGroup.eleIcon.texture = StatusGroup.eleIcon:CreateTexture(nil, "ARTWORK")
StatusGroup.eleIcon.texture:SetAllPoints()
StatusGroup.eleIcon.texture:SetTexture("Interface\\Icons\\Spell_Frost_SummonWaterElemental")
StatusGroup.eleIcon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

-- THE FIX: Here is the text that sits below the frame
StatusGroup.eleIcon.text = StatusGroup.eleIcon:CreateFontString(nil, "OVERLAY")
StatusGroup.eleIcon.text:SetFont(addonTable.MainFont or "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
StatusGroup.eleIcon.text:SetPoint("TOP", StatusGroup.eleIcon, "BOTTOM", 0, -4) -- Pushed 4 pixels below the icon
StatusGroup.eleIcon:Hide()


StatusGroup:SetScript("OnUpdate", function(self, elapsed)
    -- Optimized update frequency (every 0.1 seconds)
    self.timer = (self.timer or 0) + elapsed
    if self.timer < 0.1 then return end
    self.timer = 0

    -- Health & Class Color Logic
    local hp, maxHp = UnitHealth("player"), UnitHealthMax("player")
    healthBar:SetMinMaxValues(0, maxHp > 0 and maxHp or 1); healthBar:SetValue(hp)
    
    local _, class = UnitClass("player")
    local color = class and RAID_CLASS_COLORS[class]
    if color then healthBar:SetStatusBarColor(color.r, color.g, color.b) end

    if UnitAffectingCombat("player") then
        healthBar.text:SetText(FormatValue(hp))
    else
        healthBar.text:SetText(FormatValue(maxHp))
    end

    -- Mana Logic
    local mp, maxMp = UnitPower("player"), UnitPowerMax("player")
    manaBar:SetMinMaxValues(0, maxMp > 0 and maxMp or 1); manaBar:SetValue(mp)
    manaBar.text:SetText(string.format("%s / %s", FormatValue(mp), FormatValue(maxMp)))

    -- Update Haste Tracking
    if UnitAffectingCombat("player") then
        local currentHaste = UnitSpellHaste("player")
        local r, g, b = 1, 1, 1 -- Default White

        if currentHaste >= 50 then r, g, b = 0, 1, 1      -- High Haste/Lust (Cyan)
        elseif currentHaste >= 25 then r, g, b = 0, 1, 0  -- Good Haste (Green)
        elseif currentHaste >= 10 then r, g, b = 1, 1, 0  -- Moderate Haste (Yellow)
        end

        StatusGroup.hasteText:SetTextColor(r, g, b)
        StatusGroup.hasteText:SetFormattedText("%.2f%%", currentHaste)
        StatusGroup.hasteText:Show()
    else
        StatusGroup.hasteText:Hide()
    end

    -- Monitor Eating/Drinking
    StatusGroup.foodIcon:Hide()
    StatusGroup.drinkIcon:Hide()
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then break end
        
        if aura.name == "Food" then
            StatusGroup.foodIcon.auraIndex = i
            StatusGroup.foodIcon:Show()
        elseif aura.name == "Drink" then
            StatusGroup.drinkIcon.auraIndex = i
            StatusGroup.drinkIcon:Show()
        end
    end

    -- ==========================================
    -- NEW: Frost Elemental Timer Update Logic
    -- ==========================================
    -- In Classic/WotLK, the Water Elemental is tracked as a guardian in Totem Slot 1 or 2.
    local haveTotem, totemName, startTime, duration = GetTotemInfo(1)
    
    -- If it's not in slot 1, check slot 2 (Sometimes shifts based on other guardians)
    if not haveTotem or totemName == "" then
        haveTotem, totemName, startTime, duration = GetTotemInfo(2)
    end

    if haveTotem and totemName and totemName ~= "" and duration > 0 then
        StatusGroup.eleIcon:Show()
        
        -- Calculate how much time is remaining
        local timeLeft = (startTime + duration) - GetTime()
        
        if timeLeft > 0 then
            -- Set the text string to show the remaining seconds
            StatusGroup.eleIcon.text:SetFormattedText("%.0f", timeLeft)
        else
            StatusGroup.eleIcon:Hide()
        end
    else
        StatusGroup.eleIcon:Hide()
    end
end)

-- Hover tooltip for player frame
StatusGroup:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetUnit("player")
    GameTooltip:Show()
end)
StatusGroup:SetScript("OnLeave", function() GameTooltip:Hide() end)