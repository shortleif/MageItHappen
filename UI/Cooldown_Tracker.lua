local addonName, addonTable = ...
-- 1. Create the Main Container with Backdrop
local CDTracker = CreateFrame("Frame", "MIH_CooldownTracker", UIParent, "BackdropTemplate")

-- Configuration
local ICON_SIZE_SHORT = 40
local ICON_SIZE_LONG = 40
local SPACING = 4
local PADDING = 6 -- Space between icons and the edge of the background

-- Spell IDs (TBC Anniversary)
local SHORT_CDS = {
    2139,  -- Counterspell
    122,   -- Frost Nova
    1953,  -- Blink
    120,   -- Cone of Cold
    27079, -- Fire Blast
    11426, -- Ice Barrier
    543, -- Fire Ward
}

local LONG_CDS = {
    12042, -- Arcane Power
    12472, -- Icy Veins
    11958, -- Cold Snap
    45438, -- Ice Block
    12051, -- Evocation
    31687, -- Summon Water Elemental
}

-- 2. Setup the Background Visuals
CDTracker:SetSize(((ICON_SIZE_LONG + SPACING) * #LONG_CDS) + (PADDING * 2), 120) -- Dynamic width based on icons
CDTracker:SetPoint("CENTER", 0, -210)
--[[CDTracker:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true, tileSize = 5, edgeSize = 1,
})
CDTracker:SetBackdropColor(0, 0, 0, 0.5) -- Semi-transparent black
CDTracker:SetBackdropBorderColor(0, 0, 0, 0.8)
]]--

-- Helper to create an icon button
local function CreateCDIcon(parent, spellID, size)
    local btn = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    btn:SetSize(size, size * 0.66) 
    
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
        btn.icon:SetTexture(spellInfo.iconID)
    end
    
    btn.icon:SetTexCoord(0.07, 0.93, 0.2, 0.8) 

    btn.cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cd:SetAllPoints()
    btn.cd:SetDrawEdge(true)
    btn.cd:SetHideCountdownNumbers(false) 

    btn.spellID = spellID
    return btn
end

-- 3. Create Row Containers (Anchored inside the background)
local shortRow = CreateFrame("Frame", "MIH_ShortCDRow", CDTracker)
shortRow:SetPoint("TOP", 0, -PADDING)
shortRow:SetSize((ICON_SIZE_SHORT + SPACING) * #SHORT_CDS, ICON_SIZE_SHORT)

local longRow = CreateFrame("Frame", "MIH_LongCDRow", CDTracker)
longRow:SetPoint("BOTTOM", 0, PADDING)
longRow:SetSize((ICON_SIZE_LONG + SPACING) * #LONG_CDS, ICON_SIZE_LONG)

-- Populate Rows
local allIcons = {}
for i, id in ipairs(SHORT_CDS) do
    local icon = CreateCDIcon(shortRow, id, ICON_SIZE_SHORT)
    icon:SetPoint("LEFT", (i - 1) * (ICON_SIZE_SHORT + SPACING), 0)
    table.insert(allIcons, icon)
end

for i, id in ipairs(LONG_CDS) do
    local icon = CreateCDIcon(longRow, id, ICON_SIZE_LONG)
    icon:SetPoint("LEFT", (i - 1) * (ICON_SIZE_LONG + SPACING), 0)
    table.insert(allIcons, icon)
end

-- Update Logicqqqqqqqqqqqqqq
CDTracker:SetScript("OnUpdate", function(self, elapsed)
    for _, icon in ipairs(allIcons) do
        local start, duration = GetSpellCooldown(icon.spellID)
        
        if start and start > 0 and duration > 1.5 then
            icon.cd:SetCooldown(start, duration)
            icon.icon:SetDesaturated(true)
            icon:SetAlpha(0.6)
        else
            icon.cd:SetCooldown(0, 0)
            icon.icon:SetDesaturated(false) 
            icon:SetAlpha(1.0)
        end
    end
end)