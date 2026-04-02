local addonName, addonTable = ...
local Config = CreateFrame("Frame", "MageItHappenConfigPanel", UIParent)
Config.name = "MageItHappen"

Config:RegisterEvent("ADDON_LOADED")
Config:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end
    
-- Add this to your default settings in ADDON_LOADED
MageItHappenDB = MageItHappenDB or {
    apWaitWindow = 20,
    ivWaitWindow = 10,
    showTTD = true,
    showOnlyInEncounter = false, -- New Setting
}

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(Config, Config.name)
        Settings.RegisterAddOnCategory(category)
    end
end)

local title = Config:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("MageItHappen Settings")

local checkboxCount = 0
local function CreateCheckbox(label, dbKey, yOffset)
    checkboxCount = checkboxCount + 1
    local globalName = "MIH_Checkbox_" .. checkboxCount
    
    local check = CreateFrame("CheckButton", globalName, Config, "InterfaceOptionsCheckButtonTemplate")
    check:SetPoint("TOPLEFT", 16, yOffset)
    
    local text = _G[globalName .. "Text"]
    text:SetText(label)
    
    check:SetScript("OnShow", function(self)
        self:SetChecked(MageItHappenDB[dbKey])
    end)
    
    check:SetScript("OnClick", function(self)
        MageItHappenDB[dbKey] = self:GetChecked()
        local ttdFrame = _G["MyTTDVisualFrame"]
        if dbKey == "showTTD" and ttdFrame then
            if self:GetChecked() then ttdFrame:Show() else ttdFrame:Hide() end
        end
    end)
    return check
end

local function CreateSlider(name, label, minVal, maxVal, dbKey, yOffset)
    local slider = CreateFrame("Slider", name, Config, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 20, yOffset)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetSize(180, 20)
    
    local text = _G[name .. "Text"]
    slider:SetScript("OnShow", function(self)
        local val = MageItHappenDB[dbKey]
        self:SetValue(val)
        text:SetText(label .. ": " .. val .. "s")
    end)
    
    slider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value)
        MageItHappenDB[dbKey] = val
        text:SetText(label .. ": " .. val .. "s")
    end)
    
    return slider
end

CreateCheckbox("Display Time-To-Die (TTD) Text", "showTTD", -60)
CreateCheckbox("Show TTD in Boss Encounters Only", "showOnlyInEncounter", -120)
CreateSlider("MIH_AP_Slider", "Arcane Power Wait Window", 0, 60, "apWaitWindow", -120)
CreateSlider("MIH_IV_Slider", "Icy Veins Wait Window", 0, 60, "ivWaitWindow", -170)

addonTable.Config = Config