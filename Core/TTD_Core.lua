local addonName, addonTable = ...
local TTD_Core = {}

-- Configuration
local SAMPLE_SIZE = 15 
local UPDATE_INTERVAL = 1.0 

-- Internal State
local healthHistory = {}
local lastUpdate = 0

function TTD_Core.OnUpdate()
    local now = GetTime()
    if now - lastUpdate >= UPDATE_INTERVAL then
        local health = UnitHealth("target")
        local maxHealth = UnitHealthMax("target")
        
        if health > 0 and maxHealth > 0 then
            table.insert(healthHistory, {h = health, t = now})
            if #healthHistory > SAMPLE_SIZE then
                table.remove(healthHistory, 1)
            end
        else
            wipe(healthHistory)
        end
        lastUpdate = now
    end
end

function TTD_Core.GetCurrentTTD()
    local count = #healthHistory
    if count < 2 then return 999 end 

    local first = healthHistory[1]
    local last = healthHistory[count]
    
    local healthDiff = first.h - last.h
    local timeDiff = last.t - first.t
    
    if healthDiff <= 0 or timeDiff <= 0 then
        return 999 
    end

    local dps = healthDiff / timeDiff
    local currentHealth = UnitHealth("target")
    
    return currentHealth / dps
end

-- Export to shared table
addonTable.TTD_Core = TTD_Core