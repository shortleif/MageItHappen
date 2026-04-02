local addonName, addonTable = ...
local Castbar = CreateFrame("Frame", "MageCustomCastbar", UIParent, "BackdropTemplate")

-- Configuration
local WIDTH, HEIGHT = 250, 25
local TICK_COLOR = {1, 1, 1, 0.6} -- White ticks

-- Setup Visuals
Castbar:SetSize(WIDTH, HEIGHT)
Castbar:SetPoint("CENTER", 0, -150) -- Position below the TTD text
Castbar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
Castbar:SetBackdropColor(0, 0, 0, 0.5)
Castbar:SetBackdropBorderColor(0, 0, 0, 1)

-- The Status Bar (The actual moving progress)
Castbar.Bar = CreateFrame("StatusBar", nil, Castbar)
Castbar.Bar:SetAllPoints()
Castbar.Bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
Castbar.Bar:SetStatusBarColor(0.2, 0.5, 1) -- Mage Blue

-- Text Elements
Castbar.Text = Castbar.Bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
Castbar.Text:SetPoint("CENTER")

-- Tick Pool (To reuse lines for performance)
Castbar.Ticks = {}
local function GetTickLine(i)
    if not Castbar.Ticks[i] then
        Castbar.Ticks[i] = Castbar.Bar:CreateTexture(nil, "OVERLAY")
        Castbar.Ticks[i]:SetColorTexture(unpack(TICK_COLOR))
        Castbar.Ticks[i]:SetSize(1, HEIGHT)
    end
    return Castbar.Ticks[i]
end

local function HideTicks()
    for _, tick in pairs(Castbar.Ticks) do tick:Hide() end
end

-- 3. Logic: Update Cast/Channel
Castbar:RegisterEvent("UNIT_SPELLCAST_START")
Castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
Castbar:RegisterEvent("UNIT_SPELLCAST_STOP")
Castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
Castbar:RegisterEvent("UNIT_SPELLCAST_DELAYED")
Castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")

Castbar:SetScript("OnEvent", function(self, event, unit)
    if unit ~= "player" then return end
    
    local name, _, _, startTime, endTime, _, _, spellID = UnitCastingInfo("player")
    local isChannel = false
    
    if not name then
        name, _, _, startTime, endTime, _, spellID = UnitChannelInfo("player")
        isChannel = true
    end

    if name then
        self.startTime = startTime / 1000
        self.endTime = endTime / 1000
        self.duration = self.endTime - self.startTime
        self.isChannel = isChannel
        self.spellName = name
        self.Bar:SetMinMaxValues(0, self.duration)
        self:Show()
        
        -- Handle Ticks (Arcane Missiles = 5, Evocation = 4)
        HideTicks()
        local tickCount = 0
        if name == "Arcane Missiles" then tickCount = 5
        elseif name == "Evocation" then tickCount = 4
        elseif name == "Blizzard" then tickCount = 8 end
        
        if tickCount > 0 then
            for i = 1, tickCount - 1 do
                local line = GetTickLine(i)
                local pos = (i / tickCount) * WIDTH
                line:SetPoint("LEFT", Castbar.Bar, "LEFT", pos, 0)
                line:Show()
            end
        end
    else
        self:Hide()
    end
end)

Castbar:SetScript("OnUpdate", function(self, elapsed)
    if not self.startTime then return end
    local now = GetTime()
    local progress = self.isChannel and (self.endTime - now) or (now - self.startTime)
    self.Bar:SetValue(progress)
    
    -- AB Tracker Integration
    local _, _, stackCount = UnitDebuff("player", "Arcane Blast")
    if stackCount and stackCount > 0 then
        self.Text:SetText(string.format("%s (%d)", self.spellName, stackCount))
        -- Change color based on AB stacks (Redder as stacks increase)
        self.Bar:SetStatusBarColor(0.2 + (stackCount * 0.2), 0.5 - (stackCount * 0.1), 1 - (stackCount * 0.2))
    else
        self.Text:SetText(self.spellName)
        self.Bar:SetStatusBarColor(0.2, 0.5, 1)
    end
end)

Castbar:Hide() -- Hide initially