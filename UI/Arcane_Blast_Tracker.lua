local addonName, addonTable = ...

-- 1. Create the Frame
local ABTracker = CreateFrame("Frame", "MIH_ArcaneBlastTracker", UIParent, "BackdropTemplate")
ABTracker:SetSize(32, 32) -- Matches Intellect Reminder size

-- 2. Visual Elements
ABTracker.icon = ABTracker:CreateTexture(nil, "ARTWORK")
ABTracker.icon:SetAllPoints()
ABTracker.icon:SetTexture("Interface\\Icons\\Spell_Arcane_Blast")
ABTracker.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

ABTracker.stackText = ABTracker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ABTracker.stackText:SetPoint("BOTTOMRIGHT", ABTracker, "BOTTOMRIGHT", 12, 2)
ABTracker.stackText:SetTextColor(1, 1, 1)

ABTracker.timerText = ABTracker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
ABTracker.timerText:SetPoint("BOTTOM", ABTracker, "TOP", 0, 2)

-- 3. Placement Logic (Mimics Intellect Reminder)
local function UpdateABAnchor()
    local intellect = _G["MIH_IntellectReminder"]
    if intellect then
        ABTracker:ClearAllPoints()
        ABTracker:SetPoint("RIGHT", intellect, "LEFT", -4, 0)
    else
        -- Fallback if Intellect isn't loaded (centered offset)
        ABTracker:SetPoint("CENTER", UIParent, "CENTER", -0, -112)
    end
end

-- 4. Tracking Logic
local function UpdateArcaneBlast()
    local name, count, expirationTime
    
    -- In TBC, Arcane Blast is a debuff ("HARMFUL") on the player
    for i = 1, 40 do
        local n, _, c, _, _, e, _, _, _, spellId = UnitAura("player", i, "HARMFUL")
        if not n then break end
        if spellId == 36032 then -- Arcane Blast TBC ID
            name, count, expirationTime = n, c, e
            break
        end
    end

    if name then
        ABTracker:Show()
        -- Only show stacks if > 1
        ABTracker.stackText:SetText(count > 1 and count or "")
        
        local remaining = (expirationTime or 0) - GetTime()
        if remaining > 0 then
            ABTracker.timerText:SetFormattedText("%.1fs", remaining)
        else
            ABTracker.timerText:SetText("")
        end
        
        -- Red at 3 stacks (TBC Max)
        if count >= 3 then
            ABTracker.stackText:SetTextColor(1, 0.2, 0.2)
        else
            ABTracker.stackText:SetTextColor(1, 1, 1)
        end
    else
        ABTracker:Hide()
    end
end

-- 5. Events
ABTracker:RegisterEvent("PLAYER_ENTERING_WORLD")
ABTracker:RegisterEvent("UNIT_AURA")
ABTracker:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateABAnchor()
        UpdateArcaneBlast()
    elseif unit == "player" then
        UpdateArcaneBlast()
    end
end)

ABTracker:SetScript("OnUpdate", function(self)
    if self:IsVisible() then UpdateArcaneBlast() end
end)

ABTracker:Hide()