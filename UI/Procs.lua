local addonName, addonTable = ...
local Procs = CreateFrame("Frame", "MIH_ProcGroup", UIParent)

-- 1. Configuration & Position
local WIDTH, HEIGHT = 250, 68 -- Increased height to accommodate two icons + spacing
local ICON_SIZE = 32
local SPACING = 4
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
local function CreateProcIcon(texture, isHarmful)
    local b = CreateFrame("Button", nil, Procs, "BackdropTemplate")
    b:SetSize(ICON_SIZE, ICON_SIZE)
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
            -- Use HARMFUL for target debuffs, HELPFL for player buffs
            local filter = isHarmful and "HARMFUL" or "HELPFUL"
            local unit = isHarmful and "target" or "player"
            GameTooltip:SetUnitAura(unit, self.auraIndex, filter)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:Hide()
    return b
end

-- 3. Initialize Indicators
-- Ice Lance (Target Frozen)
local iceLance = CreateProcIcon("Interface\\Icons\\Spell_Frost_FrostBlast", true)
iceLance:SetPoint("TOP", Procs, "TOP", 0, 0)

-- Clearcasting (Player Proc)
-- Icon texture: Spell_Arcane_ManaTap (Commonly used for Clearcasting)
local clearcasting = CreateProcIcon("Interface\\Icons\\Spell_Arcane_ManaTap", false)
clearcasting:SetPoint("TOP", iceLance, "BOTTOM", 0, -SPACING)

-- 4. Update Loop
Procs:SetScript("OnUpdate", function(self, elapsed)
    self.timer = (self.timer or 0) + elapsed
    if self.timer < 0.1 then return end
    self.timer = 0

    ---------------------------
    -- LOGIC: Ice Lance / Frozen
    ---------------------------
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
            ActionButtonSpellAlertManager:ShowAlert(iceLance)
        end
    else
        if iceLance:IsShown() then
            iceLance:Hide()
            ActionButtonSpellAlertManager:HideAlert(iceLance)
        end
    end

    ---------------------------
    -- LOGIC: Clearcasting
    ---------------------------
    local foundClearcasting = false
    for i = 1, 40 do
        local name = UnitAura("player", i, "HELPFUL")
        if not name then break end
        if name == "Clearcasting" then
            clearcasting.auraIndex = i
            foundClearcasting = true
            break
        end
    end

    if foundClearcasting then
        if not clearcasting:IsShown() then
            clearcasting:Show()
            ActionButtonSpellAlertManager:ShowAlert(clearcasting)
        end
    else
        if clearcasting:IsShown() then
            clearcasting:Hide()
            ActionButtonSpellAlertManager:HideAlert(clearcasting)
        end
    end
end)