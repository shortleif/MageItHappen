local addonName, addonTable = ...
local RotationTracker = {}
addonTable.RotationTracker = RotationTracker

function RotationTracker:InitializeUI()
    local frame = CreateFrame("Frame", "MIHRotationFrame", UIParent, "BackdropTemplate")
    self.frame = frame
    frame:SetSize(230, 65)
    frame:SetPoint("RIGHT", _G["MageCustomCastbar"] or UIParent, "LEFT", -45, -42)
    
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true, tileSize = 16, edgeSize = 2,
    })

    self.icons = {}
    for i = 1, 5 do
        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(i == 1 and 42 or 30, i == 1 and 42 or 30)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        if i == 1 then
            icon:SetPoint("LEFT", 12, 0)
        else
            icon:SetPoint("LEFT", self.icons[i-1], "RIGHT", 8, 0)
            icon:SetAlpha(0.6)
        end
        self.icons[i] = icon
    end

    self.stateText = frame:CreateFontString(nil, "OVERLAY")
    self.stateText:SetFont(addonTable.MainFont, 12, "OUTLINE")
    self.stateText:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 5, 2)

    self.manaText = frame:CreateFontString(nil, "OVERLAY")
    self.manaText:SetFont(addonTable.MainFont, 11, "OUTLINE")
    self.manaText:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -5, 2)
    self.manaText:SetTextColor(0.4, 0.8, 1)
end

function RotationTracker:UpdateDisplay()
    if not addonTable.Rotation then return end
    local sequence, state = addonTable.Rotation:GetSequence()
    local totalMana = addonTable.Rotation:GetTotalManaAvailable()

    if state == "IDLE" or #sequence == 0 then
        self.frame:Hide()
        return
    end

    self.frame:Show()
    
    -- Overarching Colors
    if state == "BURN" then
        self.frame:SetBackdropColor(0.4, 0, 0, 0.5)
        self.frame:SetBackdropBorderColor(0, 1, 0, 1)
        self.stateText:SetText("|cffff0000BURN|r")
    elseif state == "STARTUP" then
        self.frame:SetBackdropColor(0.2, 0.2, 0, 0.5)
        self.frame:SetBackdropBorderColor(1, 1, 0, 1)
        self.stateText:SetText("|cffffd100OPENER|r")
    else
        self.frame:SetBackdropColor(0, 0, 0, 0.5)
        self.frame:SetBackdropBorderColor(1, 0, 0, 1)
        self.stateText:SetText("|cff00ff00CONSERVE|r")
    end

    for i = 1, 5 do
        if sequence[i] then
            self.icons[i]:SetTexture(sequence[i])
            self.icons[i]:Show()
        else
            self.icons[i]:Hide()
        end
    end
    self.manaText:SetText(string.format("Eff: %d", totalMana))
end