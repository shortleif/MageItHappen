local addonName, addonTable = ...
local BuffReminders = CreateFrame("Frame", "MIH_BuffReminders", UIParent, "BackdropTemplate")

-- Configuration
local BTN_SIZE = 30
local SPACING = 4
local UPDATE_INTERVAL = 2.0 -- Update every 2 seconds

BuffReminders:SetSize((BTN_SIZE * 3) + (SPACING * 2), BTN_SIZE)
-- Anchor below the Long CD row
if _G["MIH_LongCDRow"] then
    BuffReminders:SetPoint("TOP", _G["MIH_LongCDRow"], "BOTTOM", 0, -10)
else
    BuffReminders:SetPoint("CENTER", 0, -300) -- Fallback position
end

local function CreateReminderButton(name, iconTexture)
    local btn = CreateFrame("Frame", name, BuffReminders, "BackdropTemplate")
    btn:SetSize(BTN_SIZE, BTN_SIZE)
    
    -- Aesthetic: 1px black border matching the bars
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
    btn.icon:SetTexture(iconTexture)
    
    return btn
end

-- 1. Mana Ruby (Item IDs for various ranks)
local rubyBtn = CreateReminderButton("MIH_RemindRuby", 134831)

-- 2. Intellect (Arcane Intellect/Brilliance)
local intBtn = CreateReminderButton("MIH_RemindInt", 135932)

-- 3. Armor (Mage, Ice, or Molten Armor)
local armorBtn = CreateReminderButton("MIH_RemindArmor", 132221)

-- Position buttons horizontally
rubyBtn:SetPoint("LEFT", 0, 0)
intBtn:SetPoint("LEFT", rubyBtn, "RIGHT", SPACING, 0)
armorBtn:SetPoint("LEFT", intBtn, "RIGHT", SPACING, 0)

-- Core Update Logic
local function UpdateBuffStatus()
    -- Only show out of combat
    if UnitAffectingCombat("player") then
        BuffReminders:Hide()
        return
    end
    
    BuffReminders:Show()
    
    -- 1. Check Mana Ruby (Checks for Mana Ruby, Emerald, etc.)
    local hasRuby = C_Item.GetItemCount(22044) > 0 
                 or C_Item.GetItemCount(22043) > 0 
                 or C_Item.GetItemCount(8008) > 0
    rubyBtn:SetAlpha(hasRuby and 0 or 1)

    -- 2. Check Intellect Buff
    -- Checks for Arcane Intellect and Arcane Brilliance
    local hasInt = C_UnitAuras.GetPlayerAuraBySpellID(27126) 
                or C_UnitAuras.GetPlayerAuraBySpellID(27127)
                or C_UnitAuras.GetPlayerAuraBySpellID(23028) -- Arcane Brilliance
    intBtn:SetAlpha(hasInt and 0 or 1)

    -- 3. Check Armor Buffs
    local hasArmor = C_UnitAuras.GetPlayerAuraBySpellID(27125) -- Mage Armor
                  or C_UnitAuras.GetPlayerAuraBySpellID(27124) -- Ice Armor
                  or C_UnitAuras.GetPlayerAuraBySpellID(30482) -- Molten Armor
    armorBtn:SetAlpha(hasArmor and 0 or 1)
end

-- Timer Loop: Runs every 2 seconds
local lastUpdate = 0
BuffReminders:SetScript("OnUpdate", function(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate >= UPDATE_INTERVAL then
        UpdateBuffStatus()
        lastUpdate = 0
    end
end)

-- Also update immediately on event triggers for responsiveness
BuffReminders:RegisterEvent("PLAYER_REGEN_ENABLED")
BuffReminders:RegisterEvent("PLAYER_REGEN_DISABLED")
BuffReminders:SetScript("OnEvent", UpdateBuffStatus)