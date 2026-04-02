local addonName, addonTable = ...
local SyncLogic = {}

-- Constant
local LAST_CHANCE_BUFFER = 5
local TRINKET_DURATION = 15 

function SyncLogic.EvaluateTrinketGlow(slotID, ap_CD, iv_CD)
    local TTD_Core = addonTable.TTD_Core
    if not TTD_Core then return false end

    -- Use DB values from Config.lua
    local AP_WAIT = MageItHappenDB and MageItHappenDB.apWaitWindow or 20
    local IV_WAIT = MageItHappenDB and MageItHappenDB.ivWaitWindow or 10

    local ttd = TTD_Core.GetCurrentTTD()
    
    local start, duration, _ = GetInventoryItemCooldown("player", slotID)
    local trinket_CD = (start > 0) and (start + duration - GetTime()) or 0
    local trinketReady = (trinket_CD <= 0)
    
    if ttd < TRINKET_DURATION then return false end

    local lastChanceWindowStart = trinket_CD + TRINKET_DURATION
    local lastChanceWindowEnd = lastChanceWindowStart + LAST_CHANCE_BUFFER
    local isLastChance = (ttd >= lastChanceWindowStart) and (ttd < lastChanceWindowEnd)
    
    local apImminent = (ap_CD > 0) and (ap_CD < AP_WAIT)
    local ivImminent = (iv_CD > 0) and (iv_CD < IV_WAIT)
    
    local canWaitAP = (ttd > (ap_CD + TRINKET_DURATION))
    local canWaitIV = (ttd > (iv_CD + TRINKET_DURATION))

    if isLastChance then
        if (apImminent and canWaitAP) or (ivImminent and canWaitIV) then
            return false
        else
            return true
        end
    end

    if trinketReady then
        if (apImminent and canWaitAP) or (ivImminent and canWaitIV) then
            return false
        else
            return true
        end
    end

    return false
end

addonTable.SyncLogic = SyncLogic