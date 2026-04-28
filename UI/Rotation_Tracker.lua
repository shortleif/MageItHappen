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
        icon:SetSize(i == 1 and 48 or 30, i == 1 and 48 or 30)
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
    self.stateText:SetFont(addonTable.MainFont or "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.stateText:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 5, 2)

    self.manaText = frame:CreateFontString(nil, "OVERLAY")
    self.manaText:SetFont(addonTable.MainFont or "Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    self.manaText:SetPoint("CENTER", frame, "CENTER", 25, 0)
    self.manaText:SetTextColor(1, 1, 1)
end

function RotationTracker:UpdateDisplay()
    if not addonTable.Rotation or not addonTable.Rotation.GetRotationData then return end
    
    local state, action, stacks, fbGoal = addonTable.Rotation:GetRotationData()
    
    if state == "IDLE" then
        self.frame:Hide()
        return
    end
    self.frame:Show()

    -- UI Colors based on State
    if state == "BURN" then
        self.frame:SetBackdropColor(0.4, 0, 0, 0.8)
        self.frame:SetBackdropBorderColor(1, 0, 0, 1)
        self.stateText:SetText("|cffff0000[ BURN ]|r")
    else
        self.frame:SetBackdropColor(0, 0, 0, 0.8)
        self.frame:SetBackdropBorderColor(0, 1, 0, 1)
        self.stateText:SetText("|cff00ff00[ CONSERVE ]|r")
    end

    self.manaText:SetText(action)

    -- Icon Logic: Swaps to Frostbolt at 3+ stacks during Conserve
    local tex = (stacks >= 3 and state == "CONSERVE") 
                and "Interface\\Icons\\Spell_Frost_FrostBolt02" 
                or "Interface\\Icons\\Spell_Arcane_Blast"
    
    self.icons[1]:SetTexture(tex)
    self.icons[1]:Show()
    for i = 2, 5 do self.icons[i]:Hide() end
end