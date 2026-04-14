local addonName, addonTable = ...
local Procs = CreateFrame("Frame", "MIH_ProcGroup", UIParent)

-- 1. Configuration & Position
local WIDTH, HEIGHT = 250, 32 
Procs:SetSize(WIDTH, HEIGHT)

-- Floating 400px above the castbar
if _G["MageCustomCastbar"] then
    Procs:SetPoint("BOTTOM", _G["MageCustomCastbar"], "TOP", 0, 400)
else
    Procs:SetPoint("CENTER", 0, 200)
end

local FROZEN_DEBUFFS = {
    ["Frost Nova"] = true,
    ["Freeze"] = true,    
    ["Frostbite"] = true, 
}

-- 2. Icon Factory
local function CreateProcIcon(texture)
    local b = CreateFrame("Button", nil, Procs, "BackdropTemplate")
    b:SetSize(32, 32)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexture(texture)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    -- Subtle Turquoise Base Border
    b:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    b:SetBackdropBorderColor(0, 1, 1, 1) 
    
    b:SetScript("OnEnter", function(self)
        if self.auraIndex then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetUnitAura("target", self.auraIndex, "HARMFUL")
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:Hide()
    return b
end

-- 3. Initialize Ice Lance Indicator
local iceLance = CreateProcIcon("Interface\\Icons\\Spell_Frost_FrostBlast")
iceLance:SetPoint("CENTER", Procs, "CENTER", 0, 0)

-- 4. Update Loop
Procs:SetScript("OnUpdate", function(self, elapsed)
    self.timer = (self.timer or 0) + elapsed
    if self.timer < 0.1 then return end
    self.timer = 0

    local isFrost = IsSpellKnownOrOverridesKnown(11426) or IsPlayerSpell(11426)
    local foundFrozen = false

    if isFrost and UnitExists("target") then
        for i = 1, 40 do
            local name = UnitAura("target", i, "HARMFUL")
            if not name then break end
            if FROZEN_DEBUFFS[name] then
                iceLance.auraIndex = i
                foundFrozen = true
                break
            end
        end
    end

    if foundFrozen then
        if not iceLance:IsShown() then
            iceLance:Show()
            -- AUTHENTIC BLIZZARD GLOW: The animated shimmering effect
             ActionButtonSpellAlertManager:ShowAlert(iceLance)
        end
    else
        if iceLance:IsShown() then
            iceLance:Hide()
            -- HIDE GLOW: Stop the animation
            ActionButtonSpellAlertManager:HideAlert(iceLance)
        end
    end
end)