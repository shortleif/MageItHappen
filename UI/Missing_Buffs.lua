local addonName, addonTable = ...
local BuffReminders = CreateFrame("Frame", "MIH_BuffReminders", UIParent, "BackdropTemplate")

-- Configuration
local BTN_SIZE = 30
local SPACING = 4
local UPDATE_INTERVAL = 0.5 

BuffReminders:SetSize((BTN_SIZE * 3) + (SPACING * 2), BTN_SIZE)
BuffReminders:SetFrameLevel(30)

-- Anchor logic based on Cooldown Tracker
if _G["MIH_LongCDRow"] then
    BuffReminders:SetPoint("TOP", _G["MIH_LongCDRow"], "BOTTOM", 0, -10)
else
    BuffReminders:SetPoint("CENTER", 0, -300) 
end

-- Simplified Icon Factory (Standard Frame, not a Secure Button)
local function CreateReminderIcon(spellID)
    local f = CreateFrame("Frame", nil, BuffReminders, "BackdropTemplate")
    f:SetSize(BTN_SIZE, BTN_SIZE)
    
    local info = C_Spell.GetSpellInfo(spellID)
    if info then 
        f.icon = f:CreateTexture(nil, "ARTWORK")
        f.icon:SetPoint("TOPLEFT", 1, -1)
        f.icon:SetPoint("BOTTOMRIGHT", -1, 1)
        f.icon:SetTexture(info.iconID)
    end

    f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    return f
end

-- Level-based Mana Ruby check
local rubyID = (UnitLevel("player") >= 68) and 27101 or 22044
local rubyIcon = CreateReminderIcon(rubyID) 
local intIcon = CreateReminderIcon(27126) -- Arcane Intellect
local armorIcon = CreateReminderIcon(27125) -- Mage Armor

rubyIcon:SetPoint("LEFT", 0, 0)
intIcon:SetPoint("LEFT", rubyIcon, "RIGHT", SPACING, 0)
armorIcon:SetPoint("LEFT", intIcon, "RIGHT", SPACING, 0)

local function UpdateBuffStatus()
    -- Update armor texture based on preference
    local preferredArmor = (MageItHappenDB and MageItHappenDB.preferredArmor) or 27125
    local armorInfo = C_Spell.GetSpellInfo(preferredArmor)
    if armorInfo then armorIcon.icon:SetTexture(armorInfo.iconID) end

    -- Mana Ruby Count Check
    local hasRuby = C_Item.GetItemCount(22044) > 0 or C_Item.GetItemCount(22043) > 0 or C_Item.GetItemCount(8008) > 0
    rubyIcon:SetAlpha(hasRuby and 0 or 1)

    -- Intellect Aura Check
    local hasInt = AuraUtil.FindAuraByName("Arcane Intellect", "player", "HELPFUL") 
                or AuraUtil.FindAuraByName("Arcane Brilliance", "player", "HELPFUL")
    intIcon:SetAlpha(hasInt and 0 or 1)

    -- Combined Armor Check
    local hasArmor = AuraUtil.FindAuraByName("Mage Armor", "player", "HELPFUL")
                  or AuraUtil.FindAuraByName("Ice Armor", "player", "HELPFUL")
                  or AuraUtil.FindAuraByName("Frost Armor", "player", "HELPFUL")
                  or AuraUtil.FindAuraByName("Molten Armor", "player", "HELPFUL")
    armorIcon:SetAlpha(hasArmor and 0 or 1)
end

BuffReminders:SetScript("OnUpdate", function(self, elapsed)
    self.lastUpdate = (self.lastUpdate or 0) + elapsed
    if self.lastUpdate >= UPDATE_INTERVAL then
        UpdateBuffStatus()
        self.lastUpdate = 0
    end
end)

-- Initial check
UpdateBuffStatus()