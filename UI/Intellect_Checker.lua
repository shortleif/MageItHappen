local addonName, addonTable = ...

-- 1. Main Frame
local CheckerFrame = CreateFrame("Frame", "MIH_IntellectChecker", UIParent, "BackdropTemplate")
CheckerFrame:SetSize(200, 30) -- Start with a base size, will resize dynamically
CheckerFrame:SetPoint("CENTER", 0, 250)
CheckerFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
CheckerFrame:SetBackdropColor(0, 0, 0, 0.8)
CheckerFrame:SetMovable(true)
CheckerFrame:EnableMouse(true)
CheckerFrame:RegisterForDrag("LeftButton")
CheckerFrame:SetScript("OnDragStart", CheckerFrame.StartMoving)
CheckerFrame:SetScript("OnDragStop", CheckerFrame.StopMovingOrSizing)
CheckerFrame:Hide()

local title = CheckerFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
title:SetPoint("TOP", 0, -8)
title:SetText("Missing Arcane Intellect")

-- 2. Configuration
local MANA_CLASSES = {
    ["DRUID"]   = true,
    ["HUNTER"]  = true,
    ["MAGE"]    = true,
    ["PALADIN"] = true,
    ["PRIEST"]  = true,
    ["SHAMAN"]  = true,
    ["WARLOCK"] = true,
}
-- Fallback for older clients that don't have GetClassTextureCoords
local CLASS_ICON_COORDS = {
    ["WARRIOR"] = { left = 0,     right = 0.25,   top = 0,      bottom = 0.25 },
    ["MAGE"]    = { left = 0.25,  right = 0.5,    top = 0,      bottom = 0.25 },
    ["ROGUE"]   = { left = 0.5,   right = 0.75,   top = 0,      bottom = 0.25 },
    ["DRUID"]   = { left = 0.75,  right = 1,      top = 0,      bottom = 0.25 },
    ["HUNTER"]  = { left = 0,     right = 0.25,   top = 0.25,   bottom = 0.5 },
    ["SHAMAN"]  = { left = 0.25,  right = 0.5,    top = 0.25,   bottom = 0.5 },
    ["PRIEST"]  = { left = 0.5,   right = 0.75,   top = 0.25,   bottom = 0.5 },
    ["WARLOCK"] = { left = 0.75,  right = 1,      top = 0.25,   bottom = 0.5 },
    ["PALADIN"] = { left = 0,     right = 0.25,   top = 0.5,    bottom = 0.75 },
}

local UPDATE_INTERVAL = 2.0 -- Check every 2 seconds
local buttonPool = {}

-- 3. Button Factory
local function CreatePlayerButton(parent, index)
    local b = CreateFrame("Button", "MIH_IntellectBtn" .. index, parent, "SecureActionButtonTemplate, BackdropTemplate")
    b:SetSize(180, 28)
    b:RegisterForClicks("AnyUp", "AnyDown")

    b:SetAttribute("type1", "spell")
    b:SetAttribute("spell1", "Arcane Intellect")

    b:SetAttribute("type2", "spell")
    b:SetAttribute("spell2", "Arcane Brilliance")

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(24, 24)
    b.icon:SetPoint("LEFT", 2, 0)

    b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.name:SetPoint("LEFT", b.icon, "RIGHT", 5, 0)
    b.name:SetJustifyH("LEFT")

    b:SetScript("OnEnter", function(self)
        if self.unit then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetUnit(self.unit)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    b:Hide()
    return b
end

-- 4. Main Update Logic
local function UpdateChecker()
    if InCombatLockdown() then
        return
    end

    local groupType = IsInRaid() and "raid" or "party"
    local numGroupMembers = GetNumGroupMembers()
    
    if numGroupMembers == 0 then numGroupMembers = 1; groupType = "player" end

    local missingCount = 0

    for i = 1, numGroupMembers do
        local unit = (groupType == "player") and "player" or (groupType .. i)

        if UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
            local _, class = UnitClass(unit)
            if MANA_CLASSES[class] then
                if not AuraUtil.FindAuraByName("Arcane Intellect", unit, "HELPFUL") and not AuraUtil.FindAuraByName("Arcane Brilliance", unit, "HELPFUL") then
                    missingCount = missingCount + 1
                    local btn = buttonPool[missingCount]
                    if not btn then btn = CreatePlayerButton(CheckerFrame, missingCount); table.insert(buttonPool, btn) end

                    btn.unit = unit
                    btn:SetAttribute("unit", unit)
                    btn.name:SetText(UnitName(unit))
                    
                    local tcoords = RAID_CLASS_COLORS[class]
                    if tcoords then btn.name:SetTextColor(tcoords.r, tcoords.g, tcoords.b) end

                    local classTex = CLASS_ICON_COORDS[class]
                    if classTex then
                        btn.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                        btn.icon:SetTexCoord(classTex.left, classTex.right, classTex.top, classTex.bottom)
                    end
                    
                    btn:ClearAllPoints()
                    btn:SetPoint("TOP", CheckerFrame, "TOP", 0, -30 - ((missingCount - 1) * 30))
                    btn:Show()
                end
            end
        end
    end

    for i = missingCount + 1, #buttonPool do buttonPool[i]:Hide() end

    if missingCount > 0 then
        CheckerFrame:SetHeight(30 + (missingCount * 30))
        CheckerFrame:Show()
    else
        CheckerFrame:Hide()
    end
end

-- 5. Event Handling
local EventHandler = CreateFrame("Frame")
EventHandler:RegisterEvent("PLAYER_REGEN_DISABLED")
EventHandler:RegisterEvent("PLAYER_REGEN_ENABLED")
EventHandler:RegisterEvent("GROUP_ROSTER_UPDATE")
EventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")

EventHandler.timer = 0
EventHandler:SetScript("OnUpdate", function(self, elapsed)
    if InCombatLockdown() then return end
    self.timer = self.timer + elapsed
    if self.timer >= UPDATE_INTERVAL then self.timer = 0; UpdateChecker() end
end)

EventHandler:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then return
    elseif event == "PLAYER_REGEN_ENABLED" then C_Timer.After(1, UpdateChecker)
    else UpdateChecker() end
end)

addonTable.IntellectChecker = CheckerFrame