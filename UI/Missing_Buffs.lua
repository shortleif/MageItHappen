local addonName, addonTable = ...
local BuffReminders = CreateFrame("Frame", "MIH_BuffReminders", UIParent, "BackdropTemplate")

-- Configuration
local BTN_SIZE = 30
local SPACING = 4
local UPDATE_INTERVAL = 2.0 

BuffReminders:SetSize((BTN_SIZE * 3) + (SPACING * 2), BTN_SIZE)

if _G["MIH_LongCDRow"] then
    BuffReminders:SetPoint("TOP", _G["MIH_LongCDRow"], "BOTTOM", 0, -10)
else
    BuffReminders:SetPoint("CENTER", 0, -300) 
end

local function GetPreferredArmorID()
    return (MageItHappenDB and MageItHappenDB.preferredArmor) or 27125
end

local function CreateClickableReminder(name, spellID)
    local btn = CreateFrame("CheckButton", name, BuffReminders, "SecureActionButtonTemplate, BackdropTemplate")
    btn:SetSize(BTN_SIZE, BTN_SIZE)
    
    btn:EnableMouse(true)
    btn:RegisterForClicks("AnyUp")
    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", spellID)

    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", 
        edgeFile = "Interface\\Buttons\\WHITE8X8", 
        edgeSize = 1
    })
    btn:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
    btn:SetBackdropBorderColor(0, 0, 0, 1)

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetPoint("TOPLEFT", 1, -1)
    btn.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    
    local info = C_Spell.GetSpellInfo(spellID)
    if info then btn.icon:SetTexture(info.iconID) end
    
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

    -- Update Armor Button to current preference
    local currentArmorID = GetPreferredArmorID()
    armorBtn:SetAttribute("spell", currentArmorID)
    local armorInfo = C_Spell.GetSpellInfo(currentArmorID)
    if armorInfo then armorBtn.icon:SetTexture(armorInfo.iconID) end

    -- 1. Check Mana Ruby (Item IDs)
    local hasRuby = C_Item.GetItemCount(22044) > 0 or C_Item.GetItemCount(22043) > 0 or C_Item.GetItemCount(8008) > 0
    rubyBtn:SetAlpha(hasRuby and 0 or 1)

    -- 2. Check Intellect Buff by Name (Rank Independent)
    local hasInt = AuraUtil.FindAuraByName("Arcane Intellect", "player", "HELPFUL") 
                or AuraUtil.FindAuraByName("Arcane Brilliance", "player", "HELPFUL")
    intBtn:SetAlpha(hasInt and 0 or 1)

    -- 3. Check Armor Buffs by Name (Rank Independent)
    local hasArmor = AuraUtil.FindAuraByName("Mage Armor", "player", "HELPFUL")
                  or AuraUtil.FindAuraByName("Ice Armor", "player", "HELPFUL")
                  or AuraUtil.FindAuraByName("Frost Armor", "player", "HELPFUL")
                  or AuraUtil.FindAuraByName("Molten Armor", "player", "HELPFUL")
    armorBtn:SetAlpha(hasArmor and 0 or 1)
end

local lastUpdate = 0
BuffReminders:SetScript("OnUpdate", function(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate >= UPDATE_INTERVAL then
        UpdateBuffStatus()
        lastUpdate = 0
    end
end)

BuffReminders:RegisterEvent("PLAYER_REGEN_ENABLED")
BuffReminders:RegisterEvent("PLAYER_REGEN_DISABLED")
BuffReminders:SetScript("OnEvent", UpdateBuffStatus)