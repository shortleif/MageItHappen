local addonName, addonTable = ...

local CDTracker = CreateFrame("Frame", "MIH_CooldownTracker", UIParent, "BackdropTemplate")
CDTracker:EnableMouse(false) 

local ICON_SIZE_SHORT = 40
local ICON_SIZE_LONG = 40
local SPACING = 4
local PADDING = 6 

local SHORT_CDS = { 2139, 122, 1953, 120, 2136, 11426, 543 }
local LONG_CDS = { 12042, 12472, 11958, 45438, 12051, 31687 }

local function CreateCDIcon(parent, spellID, size)
    local btn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate, BackdropTemplate")
    btn:SetSize(size, size * 0.66) 
    btn:SetFrameLevel(parent:GetFrameLevel() + 20)
    btn:RegisterForClicks("AnyDown", "AnyUp")
    
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
        btn:SetAttribute("*type1", "macro")
        btn:SetAttribute("*macrotext1", "/cast " .. spellInfo.name)
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints()
        btn.icon:SetTexture(spellInfo.iconID)
        btn.icon:SetTexCoord(0.07, 0.93, 0.2, 0.8) 
    end

    btn.cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cd:SetAllPoints()
    btn.cd:SetMouseClickEnabled(false) 
    btn.spellID = spellID
    return btn
end

local allIcons = {}
local shortRow = CreateFrame("Frame", "MIH_ShortCDRow", CDTracker)
local longRow = CreateFrame("Frame", "MIH_LongCDRow", CDTracker)

local function BuildTracker()
    if InCombatLockdown() then return end
    for _, icon in ipairs(allIcons) do icon:Hide() end
    wipe(allIcons)

    local shortIcons, longIcons = {}, {}
    for _, id in ipairs(SHORT_CDS) do
        if MageItHappenDB and MageItHappenDB.knownSpells and MageItHappenDB.knownSpells[id] then
            table.insert(shortIcons, CreateCDIcon(shortRow, id, ICON_SIZE_SHORT))
        end
    end
    for _, id in ipairs(LONG_CDS) do
        if MageItHappenDB and MageItHappenDB.knownSpells and MageItHappenDB.knownSpells[id] then
            table.insert(longIcons, CreateCDIcon(longRow, id, ICON_SIZE_LONG))
        end
    end

    for _, icon in ipairs(shortIcons) do table.insert(allIcons, icon) end
    for _, icon in ipairs(longIcons) do table.insert(allIcons, icon) end

    -- ALIGNMENT CALCULATION
    local sWidth = (#shortIcons > 0) and (((ICON_SIZE_SHORT + SPACING) * #shortIcons) - SPACING) or 250
    local lWidth = (#longIcons > 0) and (((ICON_SIZE_LONG + SPACING) * #longIcons) - SPACING) or 250
    
    -- Sync widths to other modules
    if addonTable.UpdateCastbarWidth then addonTable.UpdateCastbarWidth(sWidth) end
    if addonTable.UpdateStatusBarsWidth then addonTable.UpdateStatusBarsWidth(sWidth) end

    CDTracker:SetSize(math.max(sWidth, lWidth) + (PADDING * 2), 160)
    CDTracker:SetPoint("CENTER", 0, -210)
    
    shortRow:SetSize(sWidth, ICON_SIZE_SHORT * 0.66)
    longRow:SetSize(lWidth, ICON_SIZE_LONG * 0.66)

    -- Anchor Short CDs to Castbar bottom
    if _G["MageCustomCastbar"] then
        shortRow:SetPoint("TOP", _G["MageCustomCastbar"], "BOTTOM", 0, -4)
    else
        shortRow:SetPoint("TOP", CDTracker, "TOP", 0, -30)
    end

    for i, icon in ipairs(shortIcons) do icon:SetPoint("LEFT", (i - 1) * (ICON_SIZE_SHORT + SPACING), 0) end
    for i, icon in ipairs(longIcons) do icon:SetPoint("LEFT", (i - 1) * (ICON_SIZE_LONG + SPACING), 0) end
end

local function ScanForNewSpells()
    MageItHappenDB = MageItHappenDB or {}
    MageItHappenDB.knownSpells = MageItHappenDB.knownSpells or {}
    for _, list in ipairs({SHORT_CDS, LONG_CDS}) do
        for _, id in ipairs(list) do
            if IsPlayerSpell(id) then MageItHappenDB.knownSpells[id] = true end
        end
    end
end

CDTracker:RegisterEvent("ADDON_LOADED")
CDTracker:RegisterEvent("SPELLS_CHANGED")
CDTracker:RegisterEvent("PLAYER_REGEN_ENABLED")
CDTracker:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        ScanForNewSpells()
        BuildTracker()
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_REGEN_ENABLED" then
        ScanForNewSpells()
        BuildTracker()
    end
end)

CDTracker:SetScript("OnUpdate", function(self)
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