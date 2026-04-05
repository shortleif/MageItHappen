local addonName, addonTable = ...
local Castbar = CreateFrame("Frame", "MageCustomCastbar", UIParent, "BackdropTemplate")

if PlayerCastingBarFrame then
    PlayerCastingBarFrame:UnregisterAllEvents()
    PlayerCastingBarFrame:Hide()
    PlayerCastingBarFrame.Show = function() end 
end

local HEIGHT, dynamicWidth = 18, 250

function addonTable.UpdateCastbarWidth(width)
    Castbar:SetWidth(width)
    if Castbar.Bar then Castbar.Bar:SetWidth(width - 2) end
end

Castbar:SetSize(dynamicWidth, HEIGHT)
Castbar:SetPoint("TOP", _G["MIH_CooldownTracker"], "TOP", 0, -6)
Castbar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
Castbar:SetBackdropColor(0.1, 0.1, 0.1, 0.7); Castbar:SetBackdropBorderColor(0, 0, 0, 1)

Castbar.Bar = CreateFrame("StatusBar", nil, Castbar)
Castbar.Bar:SetPoint("TOPLEFT", 1, -1); Castbar.Bar:SetPoint("BOTTOMRIGHT", -1, 1)
Castbar.Bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8") 
Castbar.Bar:SetStatusBarColor(0.2, 0.5, 1)

-- LEGIBLE FONT FIX
Castbar.Text = Castbar.Bar:CreateFontString(nil, "OVERLAY")
Castbar.Text:SetFont(addonTable.MainFont, 12, "OUTLINE")
Castbar.Text:SetPoint("CENTER", 0, 0)

Castbar:RegisterEvent("UNIT_SPELLCAST_START")
Castbar:RegisterEvent("UNIT_SPELLCAST_DELAYED")
Castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
Castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
Castbar:RegisterEvent("UNIT_SPELLCAST_STOP")
Castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
Castbar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
Castbar:RegisterEvent("UNIT_SPELLCAST_FAILED")

Castbar:SetScript("OnEvent", function(self, event, unit)
    if unit ~= "player" then return end
    local name, _, _, startTime, endTime = UnitCastingInfo("player")
    local isChannel = false
    if not name then name, _, _, startTime, endTime = UnitChannelInfo("player"); isChannel = true end

    if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        self.Bar:SetStatusBarColor(1, 0, 0); self.Text:SetText("Interrupted")
        C_Timer.After(0.5, function() if not UnitCastingInfo("player") and not UnitChannelInfo("player") then self:SetAlpha(0) end end)
        return
    end

    if name then
        self.startTime, self.endTime = startTime / 1000, endTime / 1000
        self.duration, self.isChannel, self.spellName = self.endTime - self.startTime, isChannel, name
        self.Bar:SetMinMaxValues(0, self.duration)
        self:SetAlpha(1); self.Bar:SetStatusBarColor(0.2, 0.5, 1)
    else self:SetAlpha(0) end
end)

Castbar:SetScript("OnUpdate", function(self)
    if not self.startTime or self:GetAlpha() == 0 then return end
    local now = GetTime()
    local progress = self.isChannel and (self.endTime - now) or (now - self.startTime)
    self.Bar:SetValue(math.max(0, math.min(progress, self.duration)))

    local auraData = AuraUtil.FindAuraByName("Arcane Blast", "player", "HELPFUL")
    local stackCount = auraData and auraData.applications or 0
    self.Text:SetText(stackCount > 0 and string.format("%s (%d)", self.spellName, stackCount) or self.spellName)
end)
Castbar:SetAlpha(0)