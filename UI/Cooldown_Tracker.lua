local addonName, addonTable = ...

-- 1. Main Container
local CDTracker = CreateFrame("Frame", "MIH_CooldownTracker", UIParent, "BackdropTemplate")

-- Configuration
local ICON_SIZE_SHORT = 40
local ICON_SIZE_LONG = 40
local SPACING = 4
local PADDING = 6 

-- Spell IDs (TBC Anniversary)
local SHORT_CDS = {
    2139,  -- Counterspell
    122,   -- Frost Nova
    1953,  -- Blink
    120,   -- Cone of Cold
    27079, -- Fire Blast
    11426, -- Ice Barrier
    543,   -- Fire Ward
}

local LONG_CDS = {
    12042, -- Arcane Power
    12472, -- Icy Veins
    11958, -- Cold Snap
    45438, -- Ice Block
    12051, -- Evocation
    31687, -- Summon Water Elemental
}

-- Helper to create an icon button
local function CreateCDIcon(parent, spellID, size)
    -- Only create the icon if the player knows the spell
    if not IsPlayerSpell(spellID) then return nil end

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

-- 2. Populate Rows and Calculate Widths
local allIcons = {}
local shortIcons = {}
local longIcons = {}

-- Create Row Containers
local shortRow = CreateFrame("Frame", "MIH_ShortCDRow", CDTracker)
local longRow = CreateFrame("Frame", "MIH_LongCDRow", CDTracker)

-- Populate Short CDs
for _, id in ipairs(SHORT_CDS) do
    local icon = CreateCDIcon(shortRow, id, ICON_SIZE_SHORT)
    if icon then table.insert(shortIcons, icon) end
end

-- Populate Long CDs
for _, id in ipairs(LONG_CDS) do
    local icon = CreateCDIcon(longRow, id, ICON_SIZE_LONG)
    if icon then table.insert(longIcons, icon) end
end

-- Dynamic Width Calculation based on KNOWN spells
local shortRowWidth = (#shortIcons > 0) and (((ICON_SIZE_SHORT + SPACING) * #shortIcons) - SPACING) or 100
local longRowWidth = (#longIcons > 0) and (((ICON_SIZE_LONG + SPACING) * #longIcons) - SPACING) or 100
local maxWidth = math.max(shortRowWidth, longRowWidth)

-- Export width for Castbar/Status Bars
addonTable.shortRowWidth = shortRowWidth

-- 3. Container & Row Positioning
CDTracker:SetSize(maxWidth + (PADDING * 2), 160) 
CDTracker:SetPoint("CENTER", 0, -210)
--[[CDTracker:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true, tileSize = 5, edgeSize = 1,
})
CDTracker:SetBackdropColor(0, 0, 0, 0.5) 
CDTracker:SetBackdropBorderColor(0, 0, 0, 0.8)
]]--
shortRow:SetSize(shortRowWidth, ICON_SIZE_SHORT * 0.66)
shortRow:SetPoint("TOP", CDTracker, "TOP", 0, -30)

longRow:SetSize(longRowWidth, ICON_SIZE_LONG * 0.66)

-- Anchor individual icons within rows
for i, icon in ipairs(shortIcons) do
    icon:SetPoint("LEFT", (i - 1) * (ICON_SIZE_SHORT + SPACING), 0)
    table.insert(allIcons, icon)
end

for i, icon in ipairs(longIcons) do
    icon:SetPoint("LEFT", (i - 1) * (ICON_SIZE_LONG + SPACING), 0)
    table.insert(allIcons, icon)
end

-- 4. Update Logic
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
    
    if not longRow.anchored and _G["MIH_StatusGroup"] then
        longRow:SetPoint("TOP", _G["MIH_StatusGroup"], "BOTTOM", 0, -4)
        longRow.anchored = true
    end
end)

-- Modern, reliable event registration
CDTracker:RegisterEvent("SPELLS_CHANGED")     
CDTracker:RegisterEvent("PLAYER_LEVEL_UP")    

CDTracker:SetScript("OnEvent", function(self, event, ...)
    local newlyLearned = {}
    
    -- Check Short CDs
    for _, id in ipairs(SHORT_CDS) do
        -- If it's in the list but NOT currently in allIcons, it's new
        local isTracked = false
        for _, icon in ipairs(allIcons) do
            if icon.spellID == id then isTracked = true break end
        end
        
        if not isTracked and IsPlayerSpell(id) then
            local info = C_Spell.GetSpellInfo(id)
            if info then table.insert(newlyLearned, info.name) end
        end
    end

    -- Check Long CDs
    for _, id in ipairs(LONG_CDS) do
        local isTracked = false
        for _, icon in ipairs(allIcons) do
            if icon.spellID == id then isTracked = true break end
        end
        
        if not isTracked and IsPlayerSpell(id) then
            local info = C_Spell.GetSpellInfo(id)
            if info then table.insert(newlyLearned, info.name) end
        end
    end

    -- If we found new spells, print them specifically
    if #newlyLearned > 0 then
        local spellList = table.concat(newlyLearned, ", ")
        print("|cff00ff00MageItHappen:|r New spells learned: |cff00ccff" .. spellList .. "|r. Please type |cffffff00/reload|r to update trackers.")
    end
end)