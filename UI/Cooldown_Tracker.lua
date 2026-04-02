local addonName, addonTable = ...
local CDTracker = CreateFrame("Frame", "MIH_CooldownTracker", UIParent)

-- Configuration
local ICON_SIZE_SHORT = 40
local ICON_SIZE_LONG = 60
local SPACING = 4

-- Spell IDs (TBC Anniversary)
local SHORT_CDS = {
    2139,  -- Counterspell
    122,   -- Frost Nova
    2130,  -- Blink
    120,   -- Cone of Cold
    27079, -- Fire Blast
}

local LONG_CDS = {
    12042, -- Arcane Power
    12472, -- Icy Veins
    -- 13 & 14 are reserved for Trinkets in the logic
}

-- Helper to create an icon button
local function CreateCDIcon(parent, spellID, size)
    local btn = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    btn:SetSize(size, size * 0.66) -- 60x40 ratio
    
    -- Icon Texture
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexture(GetSpellTexture(spellID))
    -- Zoom/Crop to 60x40 without stretching
    btn.icon:SetTexCoord(0.07, 0.93, 0.2, 0.8) 

    -- Cooldown Spiral
    btn.cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cd:SetAllPoints()
    
    btn.spellID = spellID
    return btn
end

-- Create Rows
local shortRow = CreateFrame("Frame", "MIH_ShortCDRow", CDTracker)
shortRow:SetPoint("CENTER", 0, -190)
shortRow:SetSize((ICON_SIZE_SHORT + SPACING) * #SHORT_CDS, ICON_SIZE_SHORT)

local longRow = CreateFrame("Frame", "MIH_LongCDRow", CDTracker)
longRow:SetPoint("CENTER", 0, -230)
longRow:SetSize((ICON_SIZE_LONG + SPACING) * #LONG_CDS, ICON_SIZE_LONG)

-- Populate
local shortIcons = {}
for i, id in ipairs(SHORT_CDS) do
    local icon = CreateCDIcon(shortRow, id, ICON_SIZE_SHORT)
    icon:SetPoint("LEFT", (i - 1) * (ICON_SIZE_SHORT + SPACING), 0)
    shortIcons[i] = icon
end

local longIcons = {}
for i, id in ipairs(LONG_CDS) do
    local icon = CreateCDIcon(longRow, id, ICON_SIZE_LONG)
    icon:SetPoint("LEFT", (i - 1) * (ICON_SIZE_LONG + SPACING), 0)
    longIcons[i] = icon
end

-- Update Loop
CDTracker:SetScript("OnUpdate", function(self, elapsed)
    local Sync = addonTable.SyncLogic
    
    -- Update Short CDs
    for _, icon in ipairs(shortIcons) do
        local start, duration = GetSpellCooldown(icon.spellID)
        if start > 0 and duration > 1.5 then
            icon.cd:SetCooldown(start, duration)
            icon:SetAlpha(1.0)
        else
            icon:SetAlpha(0.4)
        end
    end

    -- Update Long CDs & Sync Logic
    for _, icon in ipairs(longIcons) do
        local start, duration = GetSpellCooldown(icon.spellID)
        local remaining = (start > 0) and (start + duration - GetTime()) or 0
        
        if start > 0 and duration > 1.5 then
            icon.cd:SetCooldown(start, duration)
            icon:SetAlpha(1.0)
        else
            icon:SetAlpha(0.4)
        end

        -- SYNC LOGIC (Commented out for now)
        -- We would pass the current AP/IV cooldowns into the Trinket Evaluator here.
        -- if Sync and (icon.spellID == 12042 or icon.spellID == 12472) then
        --     local apStart, apDur = GetSpellCooldown(12042)
        --     local ivStart, ivDur = GetSpellCooldown(12472)
        --     local apCD = (apStart > 0) and (apStart + apDur - GetTime()) or 0
        --     local ivCD = (ivStart > 0) and (ivStart + ivDur - GetTime()) or 0
            
        --     -- Check if Trinket 13 should "Scream" based on these CDs
        --     if Sync.EvaluateTrinketGlow(13, apCD, ivCD) then
        --         ActionButton_ShowOverlayGlow(icon) -- Glow the CD icon as a reminder
        --     else
        --         ActionButton_HideOverlayGlow(icon)
        --     end
        -- end
    end
end)