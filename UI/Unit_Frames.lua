local addonName, addonTable = ...
local UnitFrames = CreateFrame("Frame")

-- 1. Hide Blizzard Frames
local function HideBlizzard()
    local frames = { PlayerFrame, TargetFrame, TargetFrameToT, FocusFrame, PetFrame }
    for _, f in ipairs(frames) do
        if f then f:UnregisterAllEvents(); f:Hide(); f.Show = function() end end
    end
end
HideBlizzard()

-- 2. Aura (Buff) Icon Factory - 32px, No Swipe
local function CreateAuraButton(parent, unit, index)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(32, 32) 
    
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 1, -1)
    b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) 

    b:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    b:SetBackdropBorderColor(0, 0, 0, 1)

    -- BIG BOLD Countdown Text (No swipe clutter)
    b.durationText = b:CreateFontString(nil, "OVERLAY")
    b.durationText:SetFont(addonTable.MainFont, 14, "THICKOUTLINE")
    b.durationText:SetPoint("CENTER", 0, 0)
    b.durationText:SetTextColor(1, 1, 1)

    -- Stacks/Count Text
    b.count = b:CreateFontString(nil, "OVERLAY")
    b.count:SetFont(addonTable.MainFont, 12, "OUTLINE")
    b.count:SetPoint("BOTTOMRIGHT", 2, -2)

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetUnitAura(unit, index, "HELPFUL")
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return b
end

-- 3. Frame Creation Template
local function CreateUnitFrame(unit, name, width, height)
    local f = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
    f:SetSize(width, height)
    f:SetAttribute("unit", unit)
    f:RegisterForClicks("AnyUp")
    f:SetAttribute("*type1", "target")
    f:SetAttribute("*type2", "togglemenu")
    
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetUnit(self:GetAttribute("unit"))
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    f:SetBackdropColor(0, 0, 0, 0.8); f:SetBackdropBorderColor(0, 0, 0, 1)
    
    f.hp = CreateFrame("StatusBar", nil, f)
    f.hp:SetPoint("TOPLEFT", 1, -1); f.hp:SetPoint("TOPRIGHT", -1, -1)
    f.hp:SetHeight(height * 0.75)
    f.hp:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    
    f.mp = CreateFrame("StatusBar", nil, f)
    f.mp:SetPoint("TOPLEFT", f.hp, "BOTTOMLEFT", 0, -1); f.mp:SetPoint("BOTTOMRIGHT", -1, 1)
    f.mp:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    f.mp:SetStatusBarColor(0.2, 0.4, 1)
    
    -- Adjusted font size for Pet and ToT
    local mainFontSize = (unit == "targettarget" or unit == "pet") and 12 or 18
    if unit == "focus" then mainFontSize = 15 end

    f.nameText = f.hp:CreateFontString(nil, "OVERLAY")
    f.nameText:SetFont(addonTable.MainFont, mainFontSize, "OUTLINE") 
    f.nameText:SetPoint("LEFT", 6, 0)

    f.valText = f.hp:CreateFontString(nil, "OVERLAY")
    f.valText:SetFont(addonTable.MainFont, mainFontSize, "OUTLINE")
    f.valText:SetPoint("RIGHT", -6, 0)

    -- Buff Container: 40 slots for Target
    if unit == "target" then
        f.buffs = {}
        local auraParent = CreateFrame("Frame", nil, f)
        auraParent:SetSize(width, 1)
        auraParent:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -30) -- Clears castbar
        
        for i = 1, 40 do 
            local b = CreateAuraButton(auraParent, unit, i)
            local row = math.floor((i-1) / 8)
            local col = (i-1) % 8
            b:SetPoint("TOPLEFT", auraParent, "TOPLEFT", col * (32 + 2), -row * (32 + 2))
            f.buffs[i] = b
        end
    end

    -- FIXED castbar initialization order
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
        f.cb.text:SetPoint("CENTER")
    end

    return f
end

-- 4. Positioning
local target = CreateUnitFrame("target", "MIH_TargetFrame", 270, 54)
target:SetPoint("CENTER", 300, -185)

local tot = CreateUnitFrame("targettarget", "MIH_ToTFrame", 130, 22)
tot:SetPoint("LEFT", target, "RIGHT", 10, 0)

-- PET FRAME: Left of centered Status bars
local pet = CreateUnitFrame("pet", "MIH_PetFrame", 130, 22)
if _G["MIH_StatusGroup"] then
    pet:SetPoint("RIGHT", _G["MIH_StatusGroup"], "LEFT", -15, 0)
else
    pet:SetPoint("CENTER", -300, -185) -- Fallback
end

local focus = CreateUnitFrame("focus", "MIH_FocusFrame", 200, 28)
focus:SetPoint("CENTER", 570, 80)

-- 5. Update Logic
local function UpdateAuras(f, unit)
    if not f.buffs then return end
    local now = GetTime()
    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime = UnitAura(unit, i, "HELPFUL")
        local b = f.buffs[i]
        if name then
            b.icon:SetTexture(icon)
            b.count:SetText(count > 1 and tostring(count) or "")
            
            if duration and duration > 0 then
                local remaining = expirationTime - now
                if remaining > 60 then
                    b.durationText:SetText(tostring(math.floor(remaining/60)).."m")
                else
                    b.durationText:SetText(tostring(math.floor(remaining)))
                end
            else 
                b.durationText:SetText("")
            end
            b:Show()
        else b:Hide() end
    end
end

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
        elseif reaction == 4 then r, g, b = 1, 1, 0 end
    end
    f.hp:SetStatusBarColor(r, g, b)
    
    local hp, hpMax = UnitHealth(unit), UnitHealthMax(unit)
    f.hp:SetMinMaxValues(0, hpMax > 0 and hpMax or 1); f.hp:SetValue(hp)
    f.nameText:SetText(UnitName(unit))
    f.valText:SetText(hpMax > 0 and (tostring(math.floor((hp/hpMax)*100)).."%") or "0%")
    
    if f.mp then
        local mp, mpMax = UnitPower(unit), UnitPowerMax(unit)
        f.mp:SetMinMaxValues(0, mpMax > 0 and mpMax or 1); f.mp:SetValue(mp)
    end

    UpdateAuras(f, unit)

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
    if self.timer < 0.03 then return end 
    self.timer = 0
    -- Added pet frame update
    UpdateFrame(target); UpdateFrame(tot); UpdateFrame(pet); UpdateFrame(focus)
end)