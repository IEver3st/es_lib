--[[
    Everest Lib - WaitFor Utility
    Repeatedly check a condition until it returns truthy or times out
]]

---Repeatedly check a condition until it returns a truthy value or times out
---@param cb function The callback that returns a truthy value when done
---@param errorMessage? string Error message if timeout occurs
---@param timeout? number Timeout in milliseconds (default 1000)
---@return any The truthy value returned by the callback, or nil on timeout
local function waitFor(cb, errorMessage, timeout)
    timeout = timeout or 1000
    local value = cb()
    
    if value ~= nil then
        return value
    end
    
    local start = GetGameTimer and GetGameTimer() or os.time() * 1000
    
    while value == nil do
        local elapsed = (GetGameTimer and GetGameTimer() or os.time() * 1000) - start
        
        if elapsed > timeout then
            if errorMessage then
                error(errorMessage)
            end
            return nil
        end
        
        if Wait then
            Wait(0)
        end
        
        value = cb()
    end
    
    return value
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('waitFor', waitFor)

-- ============================================================================
-- ATTACH TO LIB
-- ============================================================================

lib.waitFor = waitFor

return waitFor
