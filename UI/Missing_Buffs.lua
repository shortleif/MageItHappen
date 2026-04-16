local addonName, addonTable = ...

-- 1. Create the Group Container
-- We use SecureHandlerStateTemplate on the parent only to allow the engine to hide it
local StatusGroup = CreateFrame("Frame", "MIH_StatusGroup", UIParent, "SecureHandlerStateTemplate")
StatusGroup:SetSize(80, 40)
StatusGroup:SetPoint("BOTTOM", _G["MageCustomCastbar"] or UIParent, "TOP", 0, 10)

-- This driver tells the UI engine to hide the frame if in combat, dead, or a ghost
RegisterStateDriver(StatusGroup, "visibility", "[combat][dead][ghost] hide; show")

-- 2. Helper to create a reminder icon (Purely visual frames)
local function CreateReminder(name, texture)
    -- Using a basic Frame + BackdropTemplate for your specific border style
    local f = CreateFrame("Frame", "MIH_"..name.."Reminder", StatusGroup, "BackdropTemplate")
    f:SetSize(32, 32)
    
    -- Restored your exact styling
    f:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropBorderColor(0, 0, 0, 1)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints()
    f.icon:SetTexture(texture)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    f:Hide()
    return f
end

local intBuff = CreateReminder("Intellect", "Interface\\Icons\\Spell_Holy_MagicalSavant")
intBuff:SetPoint("LEFT", 0, 0)

local armorBuff = CreateReminder("Armor", "Interface\\Icons\\Spell_Nature_AuraOfMagicResist")
armorBuff:SetPoint("LEFT", 36, 0)

-- 3. Update Logic
local function UpdateReminders()
    -- Check Intellect/Brilliance
    local hasInt = false
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        if name:find("Arcane Intellect") or name:find("Arcane Brilliance") then
            hasInt = true
            break
        end
    end
    if hasInt then intBuff:Hide() else intBuff:Show() end

    -- Check Armor
    local hasArmor = false
    local preferredArmorID = MageItHappenDB and MageItHappenDB.preferredArmor or 27125
    local pArmorName, _, pArmorIcon = GetSpellInfo(preferredArmorID)

    if pArmorName then
        for i = 1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end
            if name == pArmorName then
                hasArmor = true
                break
            end
        end
        
        if hasArmor then 
            armorBuff:Hide() 
        else 
            armorBuff:Show()
            armorBuff.icon:SetTexture(pArmorIcon)
        end
    end
end

-- 4. Events
StatusGroup:RegisterEvent("UNIT_AURA")
StatusGroup:RegisterEvent("PLAYER_ENTERING_WORLD")

StatusGroup:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" and unit ~= "player" then return end
    UpdateReminders()
end)

-- Initial Check
UpdateReminders()