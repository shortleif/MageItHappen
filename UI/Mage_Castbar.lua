local addonName, addonTable = ...
local Castbar = CreateFrame("Frame", "MageCustomCastbar", UIParent, "BackdropTemplate")

-- 1. Disable the Default Blizzard Castbar
local function DisableBlizzardCastbar()
    if PlayerCastingBarFrame then
        PlayerCastingBarFrame:UnregisterAllEvents()
        PlayerCastingBarFrame:Hide()
        PlayerCastingBarFrame.Show = function() end 
    end
end
DisableBlizzardCastbar()

-- 2. Configuration & Dynamic Sizing
local HEIGHT = 18 
local TICK_COLOR = {1, 1, 1, 0.4} 

-- Use the exported width from Cooldown_Tracker.lua
local dynamicWidth = addonTable.shortRowWidth or 250
Castbar:SetSize(dynamicWidth, HEIGHT)

-- Anchor just below the Short CD icon row
Castbar:SetPoint("TOP", _G["MIH_ShortCDRow"], "BOTTOM", 0, -2)

Castbar:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8", 
    edgeFile = "Interface\\Buttons\\WHITE8X8", 
    edgeSize = 1
})
Castbar:SetBackdropColor(0.1, 0.1, 0.1, 0.7) 
Castbar:SetBackdropBorderColor(0, 0, 0, 1)

-- The Status Bar (Flat Texture)
Castbar.Bar = CreateFrame("StatusBar", nil, Castbar)
Castbar.Bar:SetPoint("TOPLEFT", 1, -1)
Castbar.Bar:SetPoint("BOTTOMRIGHT", -1, 1)
Castbar.Bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8") 
Castbar.Bar:SetStatusBarColor(0.2, 0.5, 1)

-- Text Elements
Castbar.Text = Castbar.Bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
Castbar.Text:SetPoint("CENTER", 0, 0)

-- Tick Pool
Castbar.Ticks = {}
local function GetTickLine(i)
    if not Castbar.Ticks[i] then
        Castbar.Ticks[i] = Castbar.Bar:CreateTexture(nil, "OVERLAY")
        Castbar.Ticks[i]:SetColorTexture(unpack(TICK_COLOR))
        Castbar.Ticks[i]:SetSize(1, HEIGHT - 2)
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

Castbar:SetScript("OnEvent", function(self, event, unit)
    if unit ~= "player" then return end
    
    local name, startTime, endTime
    if event:find("CHANNEL") then
        name, _, _, startTime, endTime = UnitChannelInfo("player")
    else
        name, _, _, startTime, endTime = UnitCastingInfo("player")
    end

    if name then
        self.startTime = startTime / 1000
        self.endTime = endTime / 1000
        self.duration = self.endTime - self.startTime
        self.isChannel = event:find("CHANNEL")
        self.spellName = name
        self.Bar:SetMinMaxValues(0, self.duration)
        self:Show()
        
        HideTicks()
        local tickCount = 0
        if name == "Arcane Missiles" then tickCount = 5
        elseif name == "Evocation" then tickCount = 4
        elseif name == "Blizzard" then tickCount = 8 end
        
        if tickCount > 0 then
            for i = 1, tickCount - 1 do
                local line = GetTickLine(i)
                -- FIXED: Using dynamicWidth instead of the missing WIDTH variable
                line:SetPoint("LEFT", Castbar.Bar, "LEFT", (i / tickCount) * (dynamicWidth - 2), 0)
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
    
    -- Corrected C_UnitAuras plural namespace
    local auraData = C_UnitAuras.GetPlayerAuraBySpellID(36032) 
    local stackCount = auraData and auraData.applications or 0

    if stackCount > 0 then
        self.Text:SetText(string.format("%s (%d)", self.spellName, stackCount))
        self.Bar:SetStatusBarColor(0.2 + (stackCount * 0.1), 0.3, 0.8 - (stackCount * 0.1))
    else
        self.Text:SetText(self.spellName)
        self.Bar:SetStatusBarColor(0.2, 0.5, 1)
    end
end)

Castbar:Hide()