local addonName, addonTable = ...
local AuraBars = CreateFrame("Frame", "MIH_AuraBars", UIParent)

-- Configuration
local BAR_WIDTH, BAR_HEIGHT, SPACING = 270, 20, 2

local BuffGroup = CreateFrame("Frame", "MIH_BuffGroup", AuraBars)
local DebuffGroup = CreateFrame("Frame", "MIH_DebuffGroup", AuraBars)

BuffGroup:SetSize(BAR_WIDTH, 270)
DebuffGroup:SetSize(BAR_WIDTH, 270)
AuraBars:SetFrameStrata("HIGH")
AuraBars:SetFrameLevel(50)

-- Anchor positions
if _G["MIH_CooldownTracker"] then
    BuffGroup:SetPoint("BOTTOMLEFT", _G["MIH_CooldownTracker"], "TOPLEFT", -277, -25)
    DebuffGroup:SetPoint("BOTTOMRIGHT", _G["MIH_CooldownTracker"], "TOPRIGHT", 277, -25)
else
    BuffGroup:SetPoint("CENTER", -100, 100)
    DebuffGroup:SetPoint("CENTER", 100, 100)
end

local function CreateAuraBar(parent)
    local bar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
    bar:SetSize(BAR_WIDTH, BAR_HEIGHT)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    bar:SetBackdropColor(0, 0, 0, 0.7); bar:SetBackdropBorderColor(0, 0, 0, 1)
    
    -- Updated to 13pt for better legibility on 270px bars
    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.text:SetFont(addonTable.MainFont, 13, "OUTLINE")
    bar.text:SetTextColor(1, 1, 1, 1)
    bar.text:SetPoint("LEFT", 4, 0)

    bar.time = bar:CreateFontString(nil, "OVERLAY")
    bar.time:SetFont(addonTable.MainFont, 13, "OUTLINE")
    bar.time:SetTextColor(1, 1, 1, 1)
    bar.time:SetPoint("RIGHT", -4, 0)
    return bar
end

local buffPool, debuffPool = {}, {}

local function FindAuraByName(unit, targetName, filter)
    for i = 1, 40 do
        local name, _, count, _, duration, expirationTime = UnitAura(unit, i, filter)
        if not name then break end
        if name == targetName then return duration, expirationTime, count end
    end
    return nil
end

local function GetTrinketNames()
    local names = {}
    for _, slot in ipairs({13, 14}) do
        local id = GetInventoryItemID("player", slot)
        if id then
            local name = GetItemInfo(id)
            if name then table.insert(names, name) end
        end
    end
    return names
end

local function UpdateAuraStack(group, pool, spellString, unit, filter, includeTrinkets)
    for _, bar in ipairs(pool) do bar:Hide() end

    local activeAuras = {}
    local searchList = {}
    
    if spellString and spellString ~= "" then
        for s in spellString:gmatch("([^,]+)") do
            table.insert(searchList, (s:gsub("^%s*(.-)%s*$", "%1")))
        end
    end

    if includeTrinkets and unit == "player" then
        local trinkets = GetTrinketNames()
        for _, t in ipairs(trinkets) do table.insert(searchList, t) end
    end

    for _, spellName in ipairs(searchList) do
        local duration, expirationTime, count = FindAuraByName(unit, spellName, filter)
        if duration then
            table.insert(activeAuras, {
                name = spellName,
                duration = duration,
                expirationTime = expirationTime,
                count = count
            })
        end
    end

    -- Sort by duration (Longest at the bottom)
    table.sort(activeAuras, function(a, b)
        if a.expirationTime == 0 then return true end
        if b.expirationTime == 0 then return false end
        return a.expirationTime > b.expirationTime
    end)

    for i, data in ipairs(activeAuras) do
        if not pool[i] then pool[i] = CreateAuraBar(group) end
        local bar = pool[i]
        
        bar:SetMinMaxValues(0, (data.duration > 0) and data.duration or 1)
        local remaining = (data.expirationTime > 0) and (data.expirationTime - GetTime()) or 0
        bar:SetValue(remaining)
        
        bar.text:SetText((data.count and data.count > 1) and (data.name.." ("..data.count..")") or data.name)
        bar.time:SetText(remaining > 0 and string.format("%.1f", remaining) or "")
        
        if unit == "player" then 
            bar:SetStatusBarColor(0, 0.5, 1) 
        else 
            bar:SetStatusBarColor(0.8, 0.2, 1) 
        end
        
        bar:ClearAllPoints()
        bar:SetPoint("BOTTOM", group, "BOTTOM", 0, (i - 1) * (BAR_HEIGHT + SPACING))
        bar:Show()
    end
end

AuraBars:SetScript("OnUpdate", function(self, elapsed)
    self.timer = (self.timer or 0) + elapsed
    -- FIX: Lowered interval to 0.03 for smoother movement
    if self.timer < 0.03 then return end
    self.timer = 0
    if MageItHappenDB then
        UpdateAuraStack(BuffGroup, buffPool, MageItHappenDB.trackedBuffs, "player", "HELPFUL", MageItHappenDB.includeTrinkets)
        UpdateAuraStack(DebuffGroup, debuffPool, MageItHappenDB.trackedDebuffs, "target", "HARMFUL")
    end
end)