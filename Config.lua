local addonName, addonTable = ...
local Config = CreateFrame("Frame", "MageItHappenConfigPanel", UIParent)
Config.name = "MageItHappen"

-- 1. Initialize Database & Register with Modern Settings API
Config:RegisterEvent("ADDON_LOADED")
Config:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end
    
    -- Default Settings
    MageItHappenDB = MageItHappenDB or {
        apWaitWindow = 20,
        ivWaitWindow = 10,
        showTTD = true,
        showDamageSummary = true,
    }
    
    -- Register in the modern "Options" menu (Dragonflight/TBC Anniversary)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(Config, Config.name)
        Settings.RegisterAddOnCategory(category)
        addonTable.SettingsCategory = category
    end
end)

-- 2. UI Header
local title = Config:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("MageItHappen Settings")

-- 3. Helper: Create Checkbox (Modern Template)
local function CreateCheckbox(label, dbKey, yOffset)
    local check = CreateFrame("CheckButton", nil, Config, "InterfaceOptionsCheckButtonTemplate")
    check:SetPoint("TOPLEFT", 16, yOffset)
    local text = _G[check:GetName() .. "Text"]
    text:SetText(label)
    
    -- Load saved state
    check:SetScript("OnShow", function(self)
        self:SetChecked(MageItHappenDB[dbKey])
    end)
    
    -- Save on click
    check:SetScript("OnClick", function(self)
        MageItHappenDB[dbKey] = self:GetChecked()
        -- Trigger immediate UI updates if necessary
        if dbKey == "showTTD" and MyTTDVisualFrame then
            if self:GetChecked() then MyTTDVisualFrame:Show() else MyTTDVisualFrame:Hide() end
        end
    end)
    return check
end

-- 4. Helper: Create Slider
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

-- 5. Build the UI Layout
local ttdCheck = CreateCheckbox("Display Time-To-Die (TTD) Text", "showTTD", -60)
local dmgCheck = CreateCheckbox("Show Arcane Explosion Totals", "showDamageSummary", -90)

local apSlider = CreateSlider("MIH_AP_Slider", "Arcane Power Wait Window", 0, 60, "apWaitWindow", -140)
local ivSlider = CreateSlider("MIH_IV_Slider", "Icy Veins Wait Window", 0, 60, "ivWaitWindow", -190)

addonTable.Config = Config