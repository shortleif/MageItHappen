local addonName, addonTable = ...
-- Anchor to UIParent for center-right positioning
local AbsorbDisplay = CreateFrame("Frame", "MIH_AbsorbDisplay", UIParent)

-- 1. Configuration
local BLOCK_WIDTH, BLOCK_HEIGHT, SPACING = 40, 12, 2 -- Flipped width/height for vertical look
local VALUE_PER_BLOCK = 200 
local MAX_BLOCKS = 40 

AbsorbDisplay:SetSize(BLOCK_WIDTH, BLOCK_HEIGHT)
AbsorbDisplay:SetPoint("CENTER", UIParent, "CENTER", 150, -50)

-- 2. Color Palette
local schoolColors = {
    ["Fire Ward"]   = {1, 0.5, 0},   
    ["Frost Ward"]  = {0, 1, 1},     
    ["Mana Shield"] = {1, 0.6, 1},   
    ["Ice Barrier"] = {0, 0.5, 1},   
}

-- Order in which shields are stacked (bottom to top)
local stackOrder = {"Ice Barrier", "Mana Shield", "Fire Ward", "Frost Ward"}

-- 3. Block Pool Management
local blocks = {}
local function GetBlock(i)
    if not blocks[i] then
        local b = AbsorbDisplay:CreateTexture(nil, "OVERLAY")
        b:SetSize(BLOCK_WIDTH, BLOCK_HEIGHT)
        b:SetTexture("Interface\\Buttons\\WHITE8X8")
        
        -- Positioning: Vertical stack growing upwards from the center-right point
        if i == 1 then
            b:SetPoint("BOTTOM", AbsorbDisplay, "BOTTOM", 0, 0)
        else
            b:SetPoint("BOTTOM", blocks[i-1], "TOP", 0, SPACING)
        end
        blocks[i] = b
    end
    return blocks[i]
end

-- 4. Text Counter
local countText = AbsorbDisplay:CreateFontString(nil, "OVERLAY")
countText:SetFont(addonTable.MainFont, 16, "THICKOUTLINE")
countText:SetTextColor(1, 1, 1)
-- Positioned at the very bottom of the stack
countText:SetPoint("TOP", AbsorbDisplay, "BOTTOM", 0, -5)

-- 5. Multi-Color Update Logic
AbsorbDisplay:SetScript("OnUpdate", function(self)
    local totalAbsorb = 0
    local currentBlockIdx = 1
    
    -- Hide all blocks initially to reset the frame
    for _, b in ipairs(blocks) do b:Hide() end

    -- Iterate through shields in a consistent order to build the stack
    for _, shieldName in ipairs(stackOrder) do
        local value = addonTable.ActiveAbsorbs[shieldName] or 0
        if value >= VALUE_PER_BLOCK then
            local numBlocks = math.floor(value / VALUE_PER_BLOCK)
            local color = schoolColors[shieldName] or {1, 1, 1}
            
            -- Fill blocks for THIS specific shield with its color
            for _ = 1, numBlocks do
                if currentBlockIdx <= MAX_BLOCKS then
                    local b = GetBlock(currentBlockIdx)
                    -- CHANGED: Updated alpha from 0.9 to 0.8 (80%)
                    b:SetVertexColor(color[1], color[2], color[3], 0.8) 
                    b:Show()
                    currentBlockIdx = currentBlockIdx + 1
                end
            end
            totalAbsorb = totalAbsorb + value
        elseif value > 0 then
            totalAbsorb = totalAbsorb + value
        end
    end

    if totalAbsorb > 0 then
        countText:SetText(tostring(math.floor(totalAbsorb)))
        countText:Show()
    else
        countText:Hide()
    end
end)