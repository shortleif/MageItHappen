local addonName, addonTable = ...
-- Ensure the parent frame covers the screen so children anchor correctly
local AuraBars = CreateFrame("Frame", "MIH_AuraBars", UIParent)
AuraBars:SetAllPoints(UIParent)

-- 1. Configuration
local BAR_WIDTH, BAR_HEIGHT, SPACING = 270, 20, 2

local BuffGroup = CreateFrame("Frame", "MIH_BuffGroup", AuraBars)
local DebuffGroup = CreateFrame("Frame", "MIH_DebuffGroup", AuraBars)

-- Use dynamic height to ensure DebuffGroup stays relative to BuffGroup if needed
BuffGroup:SetWidth(BAR_WIDTH)
DebuffGroup:SetWidth(BAR_WIDTH)
AuraBars:SetFrameStrata("HIGH")
AuraBars:SetFrameLevel(50)

-- 2. Logic to apply anchors once frames are ready
local function ApplyAnchors()
    BuffGroup:ClearAllPoints()
    DebuffGroup:ClearAllPoints()

    -- Player Buffs: Centered below CD Tracker
    if _G["MIH_CooldownTracker"] then
        -- Using your 35 offset (Note: positive Y moves it UP toward/into the tracker)
        BuffGroup:SetPoint("TOP", _G["MIH_CooldownTracker"], "BOTTOM", 0, 35)
    else
        BuffGroup:SetPoint("CENTER", 0, -100)
    end

    -- Target Debuffs: Above Target Frame
    if _G["MIH_TargetFrame"] then
        -- Anchored BOTTOM to Target TOP means it grows UPWARDS
        DebuffGroup:SetPoint("BOTTOM", _G["MIH_TargetFrame"], "TOP", 0, 10)
    else
        DebuffGroup:SetPoint("CENTER", 0, 100)
    end
end

local function CreateAuraBar(parent)
    local bar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
    bar:SetSize(BAR_WIDTH, BAR_HEIGHT)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    bar:SetBackdropColor(0, 0, 0, 0.7); bar:SetBackdropBorderColor(0, 0, 0, 1)
    
    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.text:SetFont(addonTable.MainFont, 13, "OUTLINE")
    bar.text:SetPoint("LEFT", 4, 0)

    bar.time = bar:CreateFontString(nil, "OVERLAY")
    bar.time:SetFont(addonTable.MainFont, 13, "OUTLINE")
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

-- 3. Unified Update Logic with Directional Stacking
local function UpdateAuraStack(group, pool, spellString, unit, filter, growUp)
    for _, bar in ipairs(pool) do bar:Hide() end

    local activeAuras = {}
    local searchList = {}
    
    if spellString and spellString ~= "" then
        for s in spellString:gmatch("([^,]+)") do
            table.insert(searchList, (s:gsub("^%s*(.-)%s*$", "%1")))
        end
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

    -- Sort: Shortest time closest to the anchor point
    table.sort(activeAuras, function(a, b) return a.expirationTime < b.expirationTime end)

    -- Dynamic Height
    group:SetHeight(#activeAuras > 0 and (#activeAuras * (BAR_HEIGHT + SPACING)) or 1)

    for i, data in ipairs(activeAuras) do
        if not pool[i] then pool[i] = CreateAuraBar(group) end
        local bar = pool[i]
        
        bar:SetMinMaxValues(0, (data.duration > 0) and data.duration or 1)
        local remaining = (data.expirationTime > 0) and (data.expirationTime - GetTime()) or 0
        bar:SetValue(remaining)
        
        bar.text:SetText((data.count and data.count > 1) and (data.name.." ("..data.count..")") or data.name)
        bar.time:SetText(remaining > 0 and string.format("%.1f", remaining) or "")
        
        bar:SetStatusBarColor(unit == "player" and 0 or 0.8, unit == "player" and 0.5 or 0.2, 1)
        
        bar:ClearAllPoints()
        if growUp then
            -- GROW UP: Anchor BOTTOM of bar to BOTTOM of group
            bar:SetPoint("BOTTOM", group, "BOTTOM", 0, (i - 1) * (BAR_HEIGHT + SPACING))
        else
            -- GROW DOWN: Anchor TOP of bar to TOP of group
            bar:SetPoint("TOP", group, "TOP", 0, -(i - 1) * (BAR_HEIGHT + SPACING))
        end
        bar:Show()
    end
end

-- 4. Main Event/Update Loop
AuraBars:RegisterEvent("PLAYER_ENTERING_WORLD")
AuraBars:RegisterEvent("PLAYER_TARGET_CHANGED")
AuraBars:SetScript("OnEvent", ApplyAnchors)

AuraBars:SetScript("OnUpdate", function(self, elapsed)
    self.timer = (self.timer or 0) + elapsed
    if self.timer < 0.03 then return end
    self.timer = 0
    
    -- Safety check: Re-apply anchors if globals were missing during load
    if not self.anchored and _G["MIH_CooldownTracker"] and _G["MIH_TargetFrame"] then
        ApplyAnchors()
        self.anchored = true
    end

    if MageItHappenDB then
        -- Player Buffs: growUp = false (Stacks DOWN)
        UpdateAuraStack(BuffGroup, buffPool, MageItHappenDB.trackedBuffs, "player", "HELPFUL", false)
        -- Target Debuffs: growUp = true (Stacks UP)
        UpdateAuraStack(DebuffGroup, debuffPool, MageItHappenDB.trackedDebuffs, "target", "HARMFUL", true)
    end
end)