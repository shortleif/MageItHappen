local addonName, addonTable = ...
local RotationTracker = {}
addonTable.RotationTracker = RotationTracker

function RotationTracker:InitializeUI()
    local frame = CreateFrame("Frame", "MIHRotationFrame", UIParent, "BackdropTemplate")
    self.frame = frame
    frame:SetSize(180, 50)
    frame:SetPoint("RIGHT", _G["MageCustomCastbar"] or UIParent, "LEFT", -45, -42)
    
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true, tileSize = 16, edgeSize = 1,
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(0, 0, 0, 1)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    self.mainIcon = icon
    icon:SetSize(36, 36)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local text = frame:CreateFontString(nil, "OVERLAY")
    self.text = text
    text:SetFont(addonTable.MainFont, 11, "OUTLINE")
    text:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    text:SetWidth(110)
    text:SetJustifyH("LEFT")
    
    -- Show on init so you can see it's working
    self.text:SetText("Waiting for Combat...")
    self.mainIcon:SetTexture("Interface\\Icons\\Spell_Arcane_MindMastery")
end

function RotationTracker:UpdateDisplay()
    if not addonTable.Rotation or not addonTable.Rotation.GetRecommendedAction then return end

    local iconPath, labelText = addonTable.Rotation:GetRecommendedAction()

    -- If out of combat (IDLE), show standby info instead of hiding
    if not iconPath or not labelText then
        self.mainIcon:SetTexture("Interface\\Icons\\Spell_Arcane_MindMastery")
        self.text:SetText("Standby")
        return
    end

    self.mainIcon:SetTexture(iconPath)
    self.text:SetText(labelText)
end