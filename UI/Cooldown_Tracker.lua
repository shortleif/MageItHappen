local addonName, addonTable = ...

local CDTracker = CreateFrame("Frame", "MIH_CooldownTracker", UIParent, "BackdropTemplate")
CDTracker:EnableMouse(false) 

local ICON_SIZE_SHORT = 40
local ICON_SIZE_LONG = 40
local SPACING = 4
local PADDING = 6 

local SHORT_CDS = { 2139, 122, 1953, 120, 2136, 11426, 543 }
local LONG_CDS = { 12042, 12472, 11958, 45438, 12051, 31687 }
local TRINKET_SLOTS = { 13, 14 } -- Top and Bottom Trinket

local function CreateCDIcon(parent, identifier, size, isTrinket)
    local btn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate, BackdropTemplate")
    btn:SetSize(size, size * 0.66) 
    btn:SetFrameLevel(parent:GetFrameLevel() + 20)
    btn:RegisterForClicks("AnyDown", "AnyUp")
    
    if isTrinket then
        -- Trinket Logic
        local itemID = GetInventoryItemID("player", identifier)
        local texture = GetInventoryItemTexture("player", identifier)
        if texture then
            btn:SetAttribute("*type1", "item")
            btn:SetAttribute("*item1", identifier) -- Slot ID
            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetAllPoints()
            btn.icon:SetTexture(texture)
            btn.icon:SetTexCoord(0.07, 0.93, 0.2, 0.8)
        end
        btn.slotID = identifier
    else
        -- Spell Logic
        local spellInfo = C_Spell.GetSpellInfo(identifier)
        if spellInfo then
            btn:SetAttribute("*type1", "macro")
            btn:SetAttribute("*macrotext1", "/cast " .. spellInfo.name)
            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetAllPoints()
            btn.icon:SetTexture(spellInfo.iconID)
            btn.icon:SetTexCoord(0.07, 0.93, 0.2, 0.8) 
        end
        btn.spellID = identifier
    end

    btn.cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cd:SetAllPoints()
    btn.cd:SetMouseClickEnabled(false) 
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
    
    -- 1. Filter Short CDs (Only learned spells)
    for _, id in ipairs(SHORT_CDS) do
        if IsPlayerSpell(id) then 
            table.insert(shortIcons, CreateCDIcon(shortRow, id, ICON_SIZE_SHORT, false))
        end
    end
    
    -- 2. Filter Long CDs (Only learned spells)
    for _, id in ipairs(LONG_CDS) do
        if IsPlayerSpell(id) then 
            table.insert(longIcons, CreateCDIcon(longRow, id, ICON_SIZE_LONG, false))
        end
    end

    -- 3. Add Trinkets to Long CDs (Only if they have a 'Use' effect)
    for _, slotID in ipairs(TRINKET_SLOTS) do
        local itemID = GetInventoryItemID("player", slotID)
        if itemID then
            local spellName = GetItemSpell(itemID)
            if spellName then
                local _, duration, enable = GetInventoryItemCooldown("player", slotID)
                if enable == 1 then
                    table.insert(longIcons, CreateCDIcon(longRow, slotID, ICON_SIZE_LONG, true))
                end
            end
        end
    end

    for _, icon in ipairs(shortIcons) do table.insert(allIcons, icon) end
    for _, icon in ipairs(longIcons) do table.insert(allIcons, icon) end

    -- ALIGNMENT CALCULATION
    local sWidth = (#shortIcons > 0) and (((ICON_SIZE_SHORT + SPACING) * #shortIcons) - SPACING) or 250
    local lWidth = (#longIcons > 0) and (((ICON_SIZE_LONG + SPACING) * #longIcons) - SPACING) or 250
    
    if addonTable.UpdateCastbarWidth then addonTable.UpdateCastbarWidth(sWidth) end
    if addonTable.UpdateStatusBarsWidth then addonTable.UpdateStatusBarsWidth(sWidth) end

    CDTracker:SetSize(math.max(sWidth, lWidth) + (PADDING * 2), 160)
    CDTracker:SetPoint("CENTER", 0, -210)
    
    shortRow:SetSize(sWidth, ICON_SIZE_SHORT * 0.66)
    longRow:SetSize(lWidth, ICON_SIZE_LONG * 0.66)

    if _G["MageCustomCastbar"] then
        shortRow:SetPoint("TOP", _G["MageCustomCastbar"], "BOTTOM", 0, -4)
    else
        shortRow:SetPoint("TOP", CDTracker, "TOP", 0, -30)
    end

    for i, icon in ipairs(shortIcons) do icon:SetPoint("LEFT", (i - 1) * (ICON_SIZE_SHORT + SPACING), 0) end
    for i, icon in ipairs(longIcons) do icon:SetPoint("LEFT", (i - 1) * (ICON_SIZE_LONG + SPACING), 0) end
end

CDTracker:RegisterEvent("ADDON_LOADED")
CDTracker:RegisterEvent("SPELLS_CHANGED")
CDTracker:RegisterEvent("PLAYER_REGEN_ENABLED")
CDTracker:RegisterEvent("PLAYER_EQUIPMENT_CHANGED") 
CDTracker:RegisterEvent("BAG_UPDATE")
CDTracker:SetScript("OnEvent", function(self, event, arg1)
    if (event == "ADDON_LOADED" and arg1 == addonName) or event == "SPELLS_CHANGED" or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        BuildTracker()
    end
end)

CDTracker:SetScript("OnUpdate", function(self)
    local db = MageItHappenDB or {}
    local reverse = db.reverseCDSaturation

    for _, icon in ipairs(allIcons) do
        local start, duration
        if icon.slotID then
            start, duration = GetInventoryItemCooldown("player", icon.slotID)
        else
            start, duration = GetSpellCooldown(icon.spellID)
        end

        local isOnCD = (start and start > 0 and duration > 1.5)
        
        -- Determine desaturation based on reverse setting
        -- Standard: Gray on CD, Color when Ready
        -- Reversed: Color on CD, Gray when Ready
        local shouldDesaturate = false
        if reverse then
            shouldDesaturate = not isOnCD
        else
            shouldDesaturate = isOnCD
        end

        if isOnCD then
            icon.cd:SetCooldown(start, duration)
        else
            icon.cd:SetCooldown(0, 0)
        end

        icon.icon:SetDesaturated(shouldDesaturate)
        icon:SetAlpha(shouldDesaturate and 0.6 or 1.0)
    end

    if not longRow.anchored and _G["MIH_StatusGroup"] then
        longRow:SetPoint("TOP", _G["MIH_StatusGroup"], "BOTTOM", 0, -4)
        longRow.anchored = true
    end
end)