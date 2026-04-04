local addonName, addonTable = ...

-- 1. Main Container
local CDTracker = CreateFrame("Frame", "MIH_CooldownTracker", UIParent, "BackdropTemplate")
CDTracker:EnableMouse(false) -- Ensure the background doesn't block clicks

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

-- Helper to create a CLICKABLE icon button
local function CreateCDIcon(parent, spellID, size)
    -- Inherit from SecureActionButtonTemplate to allow spell casting
    local btn = CreateFrame("CheckButton", nil, parent, "SecureActionButtonTemplate, BackdropTemplate")
    btn:SetSize(size, size * 0.66) 
    
    -- Set secure attributes for casting
    btn:EnableMouse(true)
    btn:RegisterForClicks("AnyUp")
    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", spellID)
    
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
    btn.cd:SetMouseClickEnabled(false) -- Prevents the CD swipe from eating the click

    btn.spellID = spellID
    return btn
end

-- 2. Persistence and Building Logic
local allIcons = {}
local shortRow = CreateFrame("Frame", "MIH_ShortCDRow", CDTracker)
local longRow = CreateFrame("Frame", "MIH_LongCDRow", CDTracker)

local function BuildTracker()
    for _, icon in ipairs(allIcons) do icon:Hide() end
    wipe(allIcons)

    local shortIcons = {}
    local longIcons = {}

    for _, id in ipairs(SHORT_CDS) do
        if MageItHappenDB.knownSpells[id] then
            local icon = CreateCDIcon(shortRow, id, ICON_SIZE_SHORT)
            table.insert(shortIcons, icon)
            table.insert(allIcons, icon)
        end
    end

    for _, id in ipairs(LONG_CDS) do
        if MageItHappenDB.knownSpells[id] then
            local icon = CreateCDIcon(longRow, id, ICON_SIZE_LONG)
            table.insert(longIcons, icon)
            table.insert(allIcons, icon)
        end
    end

    local sWidth = (#shortIcons > 0) and (((ICON_SIZE_SHORT + SPACING) * #shortIcons) - SPACING) or 100
    local lWidth = (#longIcons > 0) and (((ICON_SIZE_LONG + SPACING) * #longIcons) - SPACING) or 100
    local maxWidth = math.max(sWidth, lWidth)

    addonTable.shortRowWidth = sWidth

    CDTracker:SetSize(maxWidth + (PADDING * 2), 160)
    CDTracker:SetPoint("CENTER", 0, -210)
    
    shortRow:SetSize(sWidth, ICON_SIZE_SHORT * 0.66)
    shortRow:SetPoint("TOP", CDTracker, "TOP", 0, -30)
    longRow:SetSize(lWidth, ICON_SIZE_LONG * 0.66)

    for i, icon in ipairs(shortIcons) do
        icon:SetPoint("LEFT", (i - 1) * (ICON_SIZE_SHORT + SPACING), 0)
    end
    for i, icon in ipairs(longIcons) do
        icon:SetPoint("LEFT", (i - 1) * (ICON_SIZE_LONG + SPACING), 0)
    end
end

local function ScanForNewSpells()
    MageItHappenDB = MageItHappenDB or {}
    MageItHappenDB.knownSpells = MageItHappenDB.knownSpells or {}
    
    local discovered = {}
    for _, list in ipairs({SHORT_CDS, LONG_CDS}) do
        for _, id in ipairs(list) do
            if IsPlayerSpell(id) and not MageItHappenDB.knownSpells[id] then
                MageItHappenDB.knownSpells[id] = true
                local info = C_Spell.GetSpellInfo(id)
                if info then table.insert(discovered, info.name) end
            end
        end
    end

    if #discovered > 0 then
        print("|cff00ff00MageItHappen:|r New spells learned: |cff00ccff" .. table.concat(discovered, ", ") .. "|r. Type |cffffff00/reload|r to update bars.")
    end
end

-- 3. Setup Events
CDTracker:RegisterEvent("ADDON_LOADED")
CDTracker:RegisterEvent("SPELLS_CHANGED")
CDTracker:RegisterEvent("PLAYER_LEVEL_UP")

CDTracker:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        ScanForNewSpells()
        BuildTracker()
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_LEVEL_UP" then
        ScanForNewSpells()
    end
end)

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