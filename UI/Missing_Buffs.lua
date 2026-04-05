local addonName, addonTable = ...
local BuffReminders = CreateFrame("Frame", "MIH_BuffReminders", UIParent, "BackdropTemplate")

local BTN_SIZE = 30
local SPACING = 4
local UPDATE_INTERVAL = 2.0 

BuffReminders:SetSize((BTN_SIZE * 3) + (SPACING * 2), BTN_SIZE)
BuffReminders:SetFrameLevel(20)

if _G["MIH_LongCDRow"] then
    BuffReminders:SetPoint("TOP", _G["MIH_LongCDRow"], "BOTTOM", 0, -10)
else
    BuffReminders:SetPoint("CENTER", 0, -300) 
end

local function GetPreferredArmorID()
    return (MageItHappenDB and MageItHappenDB.preferredArmor) or 27125
end

local function CreateClickableReminder(name, spellID)
    local btn = CreateFrame("Button", name, BuffReminders, "SecureActionButtonTemplate, BackdropTemplate")
    btn:SetSize(BTN_SIZE, BTN_SIZE)
    btn:SetFrameLevel(BuffReminders:GetFrameLevel() + 5)
    
    btn:RegisterForClicks("LeftButtonUp")
    
    local info = C_Spell.GetSpellInfo(spellID)
    if info then 
        -- FIX: Using macro approach for buff reminders
        btn:SetAttribute("type1", "macro")
        btn:SetAttribute("macrotext1", "/cast " .. info.name)
        
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetPoint("TOPLEFT", 1, -1)
        btn.icon:SetPoint("BOTTOMRIGHT", -1, 1)
        btn.icon:SetTexture(info.iconID)
    end

    btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    btn:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
    btn:SetBackdropBorderColor(0, 0, 0, 1)

    return btn
end

local rubyBtn = CreateClickableReminder("MIH_RemindRuby", 27101) 
local intBtn = CreateClickableReminder("MIH_RemindInt", 27126)
local armorBtn = CreateClickableReminder("MIH_RemindArmor", GetPreferredArmorID())

rubyBtn:SetPoint("LEFT", 0, 0)
intBtn:SetPoint("LEFT", rubyBtn, "RIGHT", SPACING, 0)
armorBtn:SetPoint("LEFT", intBtn, "RIGHT", SPACING, 0)

local function UpdateBuffStatus()
    if UnitAffectingCombat("player") then
        BuffReminders:Hide()
        return
    end
    BuffReminders:Show()

    local currentArmorID = GetPreferredArmorID()
    local armorInfo = C_Spell.GetSpellInfo(currentArmorID)
    if armorInfo then 
        armorBtn:SetAttribute("macrotext1", "/cast " .. armorInfo.name)
        armorBtn.icon:SetTexture(armorInfo.iconID) 
    end

    local hasRuby = C_Item.GetItemCount(22044) > 0 or C_Item.GetItemCount(22043) > 0 or C_Item.GetItemCount(8008) > 0
    rubyBtn:SetAlpha(hasRuby and 0 or 1)
    rubyBtn:SetMouseClickEnabled(not hasRuby)

    local hasInt = AuraUtil.FindAuraByName("Arcane Intellect", "player", "HELPFUL") 
                or AuraUtil.FindAuraByName("Arcane Brilliance", "player", "HELPFUL")
    intBtn:SetAlpha(hasInt and 0 or 1)
    intBtn:SetMouseClickEnabled(not hasInt)

    local hasArmor = AuraUtil.FindAuraByName("Mage Armor", "player", "HELPFUL")
                  or AuraUtil.FindAuraByName("Ice Armor", "player", "HELPFUL")
                  or AuraUtil.FindAuraByName("Frost Armor", "player", "HELPFUL")
                  or AuraUtil.FindAuraByName("Molten Armor", "player", "HELPFUL")
    armorBtn:SetAlpha(hasArmor and 0 or 1)
    armorBtn:SetMouseClickEnabled(not hasArmor)
end

BuffReminders:SetScript("OnUpdate", function(self, elapsed)
    self.lastUpdate = (self.lastUpdate or 0) + elapsed
    if self.lastUpdate >= UPDATE_INTERVAL then
        UpdateBuffStatus()
        self.lastUpdate = 0
    end
end)

BuffReminders:RegisterEvent("PLAYER_REGEN_ENABLED")
BuffReminders:RegisterEvent("PLAYER_REGEN_DISABLED")
BuffReminders:SetScript("OnEvent", UpdateBuffStatus)