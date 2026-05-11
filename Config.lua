local addonName, addonTable = ...

-- 1. Create the Frame immediately so 'Config' is never nil
local Config = CreateFrame("Frame", "MageItHappenConfigPanel", UIParent)
Config.name = "MageItHappen"

-- NEW: ScrollFrame setup to prevent overflow
local ScrollFrame = CreateFrame("ScrollFrame", "MageItHappenConfigScrollFrame", Config, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 8, -8)
ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 8) -- Leave room for the scrollbar on the right

local Content = CreateFrame("Frame", "MageItHappenConfigContent", ScrollFrame)
Content:SetSize(580, 700) -- Adjust height to contain the lowest elements
ScrollFrame:SetScrollChild(Content)

MageItHappenDB = MageItHappenDB or {}

Config:RegisterEvent("ADDON_LOADED")
Config:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end
    
    -- Default Settings
    local defaults = {
        apWaitWindow = 20,
        ivWaitWindow = 10,
        showTTD = true,
        showOnlyInEncounter = false,
        preferredArmor = 27128,
        showDamageSummary = true,
        trackedBuffs = "Arcane Power, Icy Veins",
        trackedDebuffs = "Frost Nova, Frostbolt",
        includeTrinkets = true,
        reverseCDSaturation = false,
        -- New Rotation Defaults
        rotationHideOutsideEncounter = true,
        rotationShowInSpec1 = true,
        rotationShowInSpec2 = false,
        trackVT = true,
        vtMP5 = 200,
        vtRollingAverageWindow = 30, -- Default to 30 seconds
        debugMode = false,
    }

    for k, v in pairs(defaults) do
        if MageItHappenDB[k] == nil then MageItHappenDB[k] = v end
    end

    self:InitializeUI()

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(Config, Config.name)
        Settings.RegisterAddOnCategory(category)
        Config.category = category
    end
end)

-- Helper: Header (Gold Color)
local function CreateHeader(text, x, y)
    local header = Content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header:SetPoint("TOPLEFT", x, y)
    header:SetText(text)
    header:SetJustifyH("LEFT")
    return header
end

-- Helper: Checkbox (Indented)
local checkboxCount = 0
local function CreateCheckbox(label, dbKey, x, y)
    checkboxCount = checkboxCount + 1
    local globalName = "MIH_Checkbox_" .. checkboxCount
    local check = CreateFrame("CheckButton", globalName, Content, "InterfaceOptionsCheckButtonTemplate")
    check:SetPoint("TOPLEFT", x + 24, y)
    _G[globalName .. "Text"]:SetText(label)
    
    check:SetScript("OnShow", function(self) self:SetChecked(MageItHappenDB[dbKey]) end)
    check:SetScript("OnClick", function(self)
        MageItHappenDB[dbKey] = self:GetChecked()
        
        -- Logic updates for specific toggles
        if dbKey == "showTTD" then
            local ttdFrame = _G["MyTTDVisualFrame"]
            if ttdFrame then
                if self:GetChecked() then ttdFrame:Show() else ttdFrame:Hide() end
            end
        end
    end)
    return check
end

-- Helper: Slider
local function CreateSlider(name, label, minVal, maxVal, dbKey, x, y)
    local slider = CreateFrame("Slider", name, Content, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x + 28, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetSize(180, 20)
    
    local text = _G[name .. "Text"]
    text:SetTextColor(1, 1, 1)
    
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

-- Helper: Dropdown
local function CreateDropdown(label, dbKey, x, y, options)
    local dropdown = CreateFrame("Frame", "MIH_Dropdown_" .. dbKey, Content, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", x + 8, y)
    
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
            info.checked = (MageItHappenDB[dbKey] == opt.id)
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

-- Helper: EditBox
local function CreateEditBox(label, dbKey, y)
    local editbox = CreateFrame("EditBox", "MIH_Edit_" .. dbKey, Content, "InputBoxTemplate")
    editbox:SetSize(500, 20)
    editbox:SetPoint("TOPLEFT", 40, y)
    editbox:SetAutoFocus(false)
    
    local text = editbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("BOTTOMLEFT", editbox, "TOPLEFT", 0, 5)
    text:SetText(label)

    editbox:SetScript("OnShow", function(self)
        self:SetText(MageItHappenDB[dbKey] or "")
    end)
    
    editbox:SetScript("OnEnterPressed", function(self)
        MageItHappenDB[dbKey] = self:GetText()
        self:ClearFocus()
    end)
end

-- 3. Build UI Layout
function Config:InitializeUI()
    local title = Content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("MageItHappen Settings")

    -- COLUMN 1
    CreateHeader("Targeting & TTD", 16, -60)
    CreateCheckbox("Display TTD Text", "showTTD", 16, -85)
    CreateCheckbox("TTD: Boss Only", "showOnlyInEncounter", 16, -120)

    CreateHeader("Buffs & AoE Tracking", 16, -180)
    CreateCheckbox("Show AoE Damage Summary", "showDamageSummary", 16, -205)
    local armorOptions = {
        { name = "Ice Armor", id = 27128 },
        { name = "Mage Armor", id = 27125 },
        { name = "Molten Armor", id = 27124 },
    }
    CreateDropdown("Preferred Armor Buff", "preferredArmor", 16, -265, armorOptions)

    -- COLUMN 2
    CreateHeader("Cooldown Sync Windows", 300, -60)
    CreateSlider("MIH_AP_Slider", "Arcane Power Window", 0, 60, "apWaitWindow", 300, -95)
    CreateSlider("MIH_IV_Slider", "Icy Veins Window", 0, 60, "ivWaitWindow", 300, -155)

    -- NEW: Rotation & Visibility Section
    CreateHeader("Rotation Tracker Visibility", 300, -215)
    CreateCheckbox("Hide Outside Encounter", "rotationHideOutsideEncounter", 300, -240)
    CreateCheckbox("Show in Primary Spec", "rotationShowInSpec1", 300, -275)
    CreateCheckbox("Show in Secondary Spec", "rotationShowInSpec2", 300, -310)
    
    CreateHeader("Shadow Priest (VT) Tracking", 300, -345)
    CreateCheckbox("Account for Vampiric Touch", "trackVT", 300, -365)
    CreateSlider("MIH_VT_Slider", "Estimated VT MP5", 0, 500, "vtMP5", 300, -410)
    CreateSlider("MIH_VTRaw_Slider", "VT Rolling Average Window (s)", 10, 60, "vtRollingAverageWindow", 300, -460)

    -- Visual Cooldown Saturation moved slightly to avoid overlap
    CreateHeader("Visuals", 16, -305)
    CreateCheckbox("Reverse CD Saturation", "reverseCDSaturation", 16, -325)
    CreateCheckbox("Enable Debug Display", "debugMode", 16, -350)

    -- BOTTOM SECTION
    local separator = Content:CreateTexture(nil, "ARTWORK")
    separator:SetSize(580, 1)
    separator:SetPoint("TOPLEFT", 16, -500)
    separator:SetColorTexture(1, 1, 1, 0.2)

    CreateHeader("Aura Tracking", 16, -520)
    CreateEditBox("My Buffs (Comma separated)", "trackedBuffs", -555)
    CreateEditBox("Target Debuffs (Comma separated)", "trackedDebuffs", -605)
    CreateCheckbox("Include Activated Trinkets", "includeTrinkets", 16, -635)
end

addonTable.Config = Config

-- Slash Command
SLASH_MAGEITHAPPEN1 = "/mih"
SlashCmdList["MAGEITHAPPEN"] = function()
    if Settings and Settings.OpenToCategory and Config.category then
        Settings.OpenToCategory(Config.category:GetID())
    else
        InterfaceOptionsFrame_OpenToCategory(Config)
    end
end