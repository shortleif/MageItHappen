local addonName, addonTable = ...
local TTD_UI = {}
addonTable.TTD_UI = TTD_UI

local FONT_SIZE_LARGE = 16

function TTD_UI:Initialize()
    local frame = CreateFrame("Frame", "MyTTDVisualFrame", UIParent, "BackdropTemplate")
    self.frame = frame
    frame:SetSize(150, 40)
    
    -- Load Saved Position
    if MageItHappenDB and MageItHappenDB.ttdPos then
        local p = MageItHappenDB.ttdPos
        frame:ClearAllPoints()
        frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        frame:SetPoint("CENTER", 0, -100) 
    end

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true, tileSize = 5, edgeSize = 1,
    })
    frame:SetBackdropColor(0, 0, 0, 0.5)
    frame:SetBackdropBorderColor(0, 0, 0, 0.8)

    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = f:GetPoint()
        -- Save position as a table of values
        if not MageItHappenDB then MageItHappenDB = {} end
        MageItHappenDB.ttdPos = { point, relativePoint, xOfs, yOfs }
    end)

    local text = frame:CreateFontString(nil, "OVERLAY")
    self.text = text
    text:SetFont(addonTable.MainFont, FONT_SIZE_LARGE, "OUTLINE")
    text:SetPoint("CENTER")
    text:SetTextColor(1, 1, 1, 1)

    self.isInBossEncounter = false
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("ENCOUNTER_START")
    frame:RegisterEvent("ENCOUNTER_END")

    frame:SetScript("OnEvent", function(f, event)
        if event == "ENCOUNTER_START" then self.isInBossEncounter = true
        elseif event == "ENCOUNTER_END" then self.isInBossEncounter = false end

        local db = MageItHappenDB
        if not db or not db.showTTD then f:Hide() return end

        if event == "PLAYER_REGEN_DISABLED" or event == "ENCOUNTER_START" then
            if db.showOnlyInEncounter then
                if self.isInBossEncounter then f:Show() else f:Hide() end
            else f:Show() end
        elseif event == "PLAYER_REGEN_ENABLED" or event == "ENCOUNTER_END" then
            if not UnitAffectingCombat("player") then f:Hide() end
        end
    end)
end

function TTD_UI:UpdateDisplay(currentTTD)
    if not self.text then return end
    if not UnitExists("target") or UnitIsDead("target") then
        self.text:SetText("No Target") 
    elseif currentTTD >= 999 then
        self.text:SetText("Calculating...")
    else
        self.text:SetText(string.format("TTD: %ds", math.floor(currentTTD + 0.5)))
    end
end