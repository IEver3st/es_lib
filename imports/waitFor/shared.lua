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

exports('waitFor', waitFor)

lib.waitFor = waitFor

return waitFor
