local addonName, addonTable = ...
local Castbar = CreateFrame("Frame", "MageCustomCastbar", UIParent, "BackdropTemplate")

-- 1. Disable Default Bar
if PlayerCastingBarFrame then
    PlayerCastingBarFrame:UnregisterAllEvents()
    PlayerCastingBarFrame:Hide()
    PlayerCastingBarFrame.Show = function() end 
end

-- 2. Configuration & Visual Setup
local HEIGHT = 18 
local TICK_COLOR = {1, 1, 1, 0.4} 
local dynamicWidth = addonTable.shortRowWidth or 250

Castbar:SetSize(dynamicWidth, HEIGHT)
Castbar:SetPoint("TOP", _G["MIH_CooldownTracker"], "TOP", 0, -6)

Castbar:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8", 
    edgeFile = "Interface\\Buttons\\WHITE8X8", 
    edgeSize = 1
})
Castbar:SetBackdropColor(0.1, 0.1, 0.1, 0.7) 
Castbar:SetBackdropBorderColor(0, 0, 0, 1)

Castbar.Bar = CreateFrame("StatusBar", nil, Castbar)
Castbar.Bar:SetPoint("TOPLEFT", 1, -1)
Castbar.Bar:SetPoint("BOTTOMRIGHT", -1, 1)
Castbar.Bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8") 
Castbar.Bar:SetStatusBarColor(0.2, 0.5, 1)

Castbar.Text = Castbar.Bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
Castbar.Text:SetPoint("CENTER", 0, 0)

-- 3. Logic: Update Cast/Channel/Interrupts
Castbar:RegisterEvent("UNIT_SPELLCAST_START")
Castbar:RegisterEvent("UNIT_SPELLCAST_DELAYED")        -- Normal cast pushback
Castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
Castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE") -- Channel pushback (lost time)
Castbar:RegisterEvent("UNIT_SPELLCAST_STOP")
Castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
Castbar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
Castbar:RegisterEvent("UNIT_SPELLCAST_FAILED")

Castbar:SetScript("OnEvent", function(self, event, unit)
    if unit ~= "player" then return end
    if not self.Bar or not self.Text then return end

    local name, _, _, startTime, endTime = UnitCastingInfo("player")
    local isChannel = false
    
    if not name then
        name, _, _, startTime, endTime = UnitChannelInfo("player")
        isChannel = true
    end

    -- Handle Interrupts/Failures
    if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        self.Bar:SetStatusBarColor(1, 0, 0) 
        self.Text:SetText("Interrupted")
        C_Timer.After(0.5, function() 
            if not UnitCastingInfo("player") and not UnitChannelInfo("player") then
                self:Hide() 
            end
        end)
        return
    end

    if name then
        self.startTime = startTime / 1000
        self.endTime = endTime / 1000
        self.duration = self.endTime - self.startTime
        self.isChannel = isChannel
        self.spellName = name
        
        self.Bar:SetMinMaxValues(0, self.duration)
        
        -- Inverse logic for Channels: progress starts at full and goes to 0
        if isChannel then
            self.Bar:SetValue(self.duration)
        else
            self.Bar:SetValue(0)
        end
        
        self:Show()
        self.Bar:SetStatusBarColor(0.2, 0.5, 1)
    else
        self:Hide()
    end
end)

Castbar:SetScript("OnUpdate", function(self, elapsed)
    if not self.startTime or not self:IsVisible() then return end
    
    local now = GetTime()
    local progress
    
    if self.isChannel then
        -- Channel: counts DOWN from duration to 0
        progress = self.endTime - now
    else
        -- Normal Cast: counts UP from 0 to duration
        progress = now - self.startTime
    end
    
    -- Clamp and update
    progress = math.max(0, math.min(progress, self.duration))
    self.Bar:SetValue(progress)
    
    -- AB Stacks Visuals
    local auraData = C_UnitAuras.GetPlayerAuraBySpellID(36032) 
    local stackCount = auraData and auraData.applications or 0

    if stackCount > 0 and not self.isChannel then
        self.Text:SetText(string.format("%s (%d)", self.spellName, stackCount))
        self.Bar:SetStatusBarColor(0.2 + (stackCount * 0.1), 0.3, 0.8 - (stackCount * 0.1))
    else
        self.Text:SetText(self.spellName)
    end
end)

Castbar:Hide()