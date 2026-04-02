local addonName, addonTable = ...
SyncLogic = {}

-- User Adjustable Variables
local AP_WAIT_WINDOW = 20
local IV_WAIT_WINDOW = 10
local LAST_CHANCE_BUFFER = 5
local TRINKET_DURATION = 15 

function SyncLogic.EvaluateTrinketGlow(slotID, ap_CD, iv_CD)
    local TTD_Core = addonTable.TTD_Core
    if not TTD_Core then return false end

    local ttd = TTD_Core.GetCurrentTTD()
    
    -- 1. Fetch Trinket Data
    local start, duration, _ = GetInventoryItemCooldown("player", slotID)
    local trinket_CD = (start > 0) and (start + duration - GetTime()) or 0
    local trinketReady = (trinket_CD <= 0)
    
    -- 2. TTD Safety Override
    if ttd < TRINKET_DURATION then return false end

    -- 3. Calculate "Use it or Lose it" Window
    local lastChanceWindowStart = trinket_CD + TRINKET_DURATION
    local lastChanceWindowEnd = lastChanceWindowStart + LAST_CHANCE_BUFFER
    local isLastChance = (ttd >= lastChanceWindowStart) and (ttd < lastChanceWindowEnd)
    
    -- 4. Check for Imminent Power Windows
    local apImminent = (ap_CD > 0) and (ap_CD < AP_WAIT_WINDOW)
    local ivImminent = (iv_CD > 0) and (iv_CD < IV_WAIT_WINDOW)
    
    -- Can we afford to wait for the Major CD?
    local canWaitAP = (ttd > (ap_CD + TRINKET_DURATION))
    local canWaitIV = (ttd > (iv_CD + TRINKET_DURATION))

    -- 5. Decision Tree
    -- Scenario: Boss is dying soon, check if we must fire now
    if isLastChance then
        if (apImminent and canWaitAP) or (ivImminent and canWaitIV) then
            return false -- Hold for sync
        else
            return true -- Scream
        end
    end

    -- Scenario: Trinket is ready, check if we should hold for upcoming CDs
    if trinketReady then
        if (apImminent and canWaitAP) or (ivImminent and canWaitIV) then
            return false -- Holding for combo
        else
            return true -- Send it
        end
    end

    return false
end

-- Export to shared table
addonTable.SyncLogic = SyncLogic