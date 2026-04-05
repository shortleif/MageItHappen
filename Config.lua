local addonName, addonTable = ...
local Config = CreateFrame("Frame", "MageItHappenConfigPanel", UIParent)
Config.name = "MageItHappen"

MageItHappenDB = MageItHappenDB or {}

Config:RegisterEvent("ADDON_LOADED")
Config:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end
    
    local defaults = {
        apWaitWindow = 20,
        ivWaitWindow = 10,
        showTTD = true,
        showOnlyInEncounter = false,
        preferredArmor = 27128,
        showDamageSummary = true,
    }

    for k, v in pairs(defaults) do
        if MageItHappenDB[k] == nil then MageItHappenDB[k] = v end
    end

    self:InitializeUI()

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(Config, Config.name)
        Settings.RegisterAddOnCategory(category)
    end
end)

-- Improved Header: Uses Gold color for clear distinction
local function CreateHeader(text, yOffset)
    local header = Config:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header:SetPoint("TOPLEFT", 16, yOffset)
    header:SetText(text)
    header:SetJustifyH("LEFT")
    return header
end

-- Improved Checkbox: Indented to 40px
local checkboxCount = 0
local function CreateCheckbox(label, dbKey, yOffset)
    checkboxCount = checkboxCount + 1
    local globalName = "MIH_Checkbox_" .. checkboxCount
    local check = CreateFrame("CheckButton", globalName, Config, "InterfaceOptionsCheckButtonTemplate")
    check:SetPoint("TOPLEFT", 40, yOffset) -- Indented
    _G[globalName .. "Text"]:SetText(label)
    
    check:SetScript("OnShow", function(self) self:SetChecked(MageItHappenDB[dbKey]) end)
    check:SetScript("OnClick", function(self) MageItHappenDB[dbKey] = self:GetChecked() end)
    return check
end

-- Improved Slider: Indented and text color changed to white
local function CreateSlider(name, label, minVal, maxVal, dbKey, yOffset)
    local slider = CreateFrame("Slider", name, Config, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 44, yOffset) -- Indented
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetSize(200, 20)
    
    local text = _G[name .. "Text"]
    text:SetTextColor(1, 1, 1) -- White text for settings
    
    slider:SetScript("OnShow", function(self)
        local val = MageItHappenDB[dbKey] or 0
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

-- Improved Dropdown: Indented
local function CreateDropdown(label, dbKey, yOffset, options)
    local dropdown = CreateFrame("Frame", "MIH_Dropdown_" .. dbKey, Config, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 24, yOffset) -- Indented alignment
    
    local text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 5)
    text:SetText(label)

    UIDropDownMenu_Initialize(dropdown, function(self)
        local info = UIDropDownMenu_CreateInfo()
        for _, opt in ipairs(options) do
            info.text = opt.name
            info.arg1 = opt.id
            info.func = function(btn, arg1)
                MageItHappenDB[dbKey] = arg1
                UIDropDownMenu_SetText(dropdown, opt.name)
                CloseDropDownMenus()
            end
            info.checked = (MageItHappenDB and MageItHappenDB[dbKey] == opt.id)
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetWidth(dropdown, 150)
    dropdown:SetScript("OnShow", function(self)
        for _, opt in ipairs(options) do
            if MageItHappenDB[dbKey] == opt.id then
                UIDropDownMenu_SetText(dropdown, opt.name)
                break
            end
        end
    end)
end

function Config:InitializeUI()
    local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("MageItHappen Settings")

    -- Targeting Section
    CreateHeader("Targeting & Time-To-Die", -60)
    CreateCheckbox("Display Time-To-Die (TTD) Text", "showTTD", -85)
    CreateCheckbox("Show TTD in Boss Encounters Only", "showOnlyInEncounter", -120)

    -- Cooldown Sync Section (Larger gap after previous group)
    CreateHeader("Cooldown Sync Windows", -180)
    CreateSlider("MIH_AP_Slider", "Arcane Power Window", 0, 60, "apWaitWindow", -215)
    CreateSlider("MIH_IV_Slider", "Icy Veins Window", 0, 60, "ivWaitWindow", -275)

    -- Buffs & AoE Section
    CreateHeader("Buffs & AoE Tracking", -340)
    CreateCheckbox("Show AoE Damage Summary", "showDamageSummary", -365)

    local armorOptions = {
        { name = "Ice Armor", id = 27128 },
        { name = "Mage Armor", id = 27125 },
        { name = "Molten Armor", id = 27124 },
    }
    CreateDropdown("Preferred Armor Buff", "preferredArmor", -425, armorOptions)
end

addonTable.Config = Config