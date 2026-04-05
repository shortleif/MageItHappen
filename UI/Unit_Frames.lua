local addonName, addonTable = ...
local UnitFrames = CreateFrame("Frame")

-- 1. Hide Blizzard Frames
local function HideBlizzard()
    local frames = { PlayerFrame, TargetFrame, TargetFrameToT, FocusFrame }
    for _, f in ipairs(frames) do
        if f then f:UnregisterAllEvents(); f:Hide(); f.Show = function() end end
    end
end
HideBlizzard()

-- 2. Frame Creation Template
local function CreateUnitFrame(unit, name, width, height)
    local f = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
    f:SetSize(width, height)
    f:SetAttribute("unit", unit)
    f:RegisterForClicks("AnyUp")
    f:SetAttribute("*type1", "target")
    f:SetAttribute("*type2", "togglemenu")
    
    f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    f:SetBackdropColor(0, 0, 0, 0.8)
    f:SetBackdropBorderColor(0, 0, 0, 1)
    
    f.hp = CreateFrame("StatusBar", nil, f)
    f.hp:SetPoint("TOPLEFT", 1, -1); f.hp:SetPoint("TOPRIGHT", -1, -1)
    f.hp:SetHeight(height * 0.75)
    f.hp:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    
    f.mp = CreateFrame("StatusBar", nil, f)
    f.mp:SetPoint("TOPLEFT", f.hp, "BOTTOMLEFT", 0, -1); f.mp:SetPoint("BOTTOMRIGHT", -1, 1)
    f.mp:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    f.mp:SetStatusBarColor(0.2, 0.4, 1)
    
    -- RESTORED: White Font + Black Outline
    local mainFontSize = (unit == "targettarget" and 12 or 18)
    if unit == "focus" then mainFontSize = 15 end

    f.nameText = f.hp:CreateFontString(nil, "OVERLAY")
    f.nameText:SetFont(addonTable.MainFont, mainFontSize, "OUTLINE") 
    f.nameText:SetTextColor(1, 1, 1, 1) -- White
    f.nameText:SetPoint("LEFT", 6, 0)

    f.valText = f.hp:CreateFontString(nil, "OVERLAY")
    f.valText:SetFont(addonTable.MainFont, mainFontSize, "OUTLINE")
    f.valText:SetTextColor(1, 1, 1, 1)
    f.valText:SetPoint("RIGHT", -6, 0)

    if unit ~= "player" and unit ~= "targettarget" then
        f.cb = CreateFrame("StatusBar", nil, f, "BackdropTemplate")
        f.cb:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -3); f.cb:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -3)
        f.cb:SetHeight(16)
        f.cb:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        f.cb:SetStatusBarColor(1, 0.7, 0)
        f.cb:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        f.cb:SetBackdropColor(0, 0, 0, 0.8); f.cb:SetBackdropBorderColor(0, 0, 0, 1)
        f.cb:Hide()

        f.cb.text = f.cb:CreateFontString(nil, "OVERLAY")
        f.cb.text:SetFont(addonTable.MainFont, 12, "OUTLINE")
        f.cb.text:SetTextColor(1, 1, 1, 1)
        f.cb.text:SetPoint("CENTER")
    end

    return f
end

-- 3. Positioning (Pixel Perfect)
local player = CreateUnitFrame("player", "MIH_PlayerFrame", 270, 54)
player:SetPoint("CENTER", -300, -185)

local target = CreateUnitFrame("target", "MIH_TargetFrame", 270, 54)
target:SetPoint("CENTER", 300, -185)

local tot = CreateUnitFrame("targettarget", "MIH_ToTFrame", 130, 22)
tot:SetPoint("TOPRIGHT", target, "BOTTOMRIGHT", 0, -18)

local focus = CreateUnitFrame("focus", "MIH_FocusFrame", 200, 28)
focus:SetPoint("CENTER", 570, 80)

-- 4. Update Logic
local function UpdateFrame(f)
    local unit = f:GetAttribute("unit")
    if not UnitExists(unit) then f:SetAlpha(0); return end
    f:SetAlpha(1)
    
    local r, g, b = 1, 0, 0 
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local color = class and RAID_CLASS_COLORS[class]
        if color then r, g, b = color.r, color.g, color.b end
    elseif UnitReaction(unit, "player") then
        local reaction = UnitReaction(unit, "player")
        if reaction >= 5 then r, g, b = 0.2, 0.8, 0.2 
        elseif reaction == 4 then r, g, b = 1, 1, 0 
        end
    end
    f.hp:SetStatusBarColor(r, g, b)
    
    local hp, hpMax = UnitHealth(unit), UnitHealthMax(unit)
    f.hp:SetMinMaxValues(0, hpMax > 0 and hpMax or 1); f.hp:SetValue(hp)
    
    f.nameText:SetText(UnitName(unit))
    f.valText:SetText(hpMax > 0 and (math.floor((hp/hpMax)*100).."%") or "0%")
    
    local mp, mpMax = UnitPower(unit), UnitPowerMax(unit)
    f.mp:SetMinMaxValues(0, mpMax > 0 and mpMax or 1); f.mp:SetValue(mp)

    if f.cb then
        local spell, _, _, start, endTime = UnitCastingInfo(unit)
        if not spell then spell, _, _, start, endTime = UnitChannelInfo(unit) end
        if spell then
            f.cb:SetMinMaxValues(start, endTime); f.cb:SetValue(GetTime()*1000)
            f.cb.text:SetText(spell); f.cb:Show()
        else f.cb:Hide() end
    end
end

UnitFrames:SetScript("OnUpdate", function(self, elapsed)
    self.timer = (self.timer or 0) + elapsed
    if self.timer < 0.02 then return end 
    self.timer = 0
    UpdateFrame(player); UpdateFrame(target); UpdateFrame(tot); UpdateFrame(focus)
end)