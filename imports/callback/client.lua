--[[
    Everest Lib - Client Callback Module
    ox_lib compatible callback system for client-server communication
    
    Usage:
    - lib.callback(name, delay, cb, ...) - Async callback with function
    - lib.callback.await(name, delay, ...) - Synchronous callback that returns values
    - lib.callback.register(name, cb) - Register a client callback for server to call
]]

-- ============================================================================
-- CALLBACK STORAGE
-- ============================================================================

local pendingCallbacks = {}
local callbackId = 0
local registeredCallbacks = {}

-- ============================================================================
-- TRIGGER SERVER CALLBACK (Async)
-- ============================================================================

---Trigger a server callback asynchronously
---@param name string The callback name registered on the server
---@param delay? number|false Delay before calling (ms) or false for immediate
---@param cb function The function to call with the result
---@vararg any Arguments to pass to the server
local function triggerCallback(name, delay, cb, ...)
    callbackId = callbackId + 1
    local id = callbackId
    local args = {...}
    
    pendingCallbacks[id] = cb
    
    if delay and delay > 0 then
        SetTimeout(delay, function()
            TriggerServerEvent('es_lib:callback', name, id, table.unpack(args))
        end)
    else
        TriggerServerEvent('es_lib:callback', name, id, table.unpack(args))
    end
end

-- ============================================================================
-- TRIGGER SERVER CALLBACK (Sync/Await)
-- ============================================================================

---Trigger a server callback and wait for the result
---@param name string The callback name registered on the server
---@param delay? number|false Delay before calling (ms) or false for immediate
---@vararg any Arguments to pass to the server
---@return any ... The values returned by the server callback
local function awaitCallback(name, delay, ...)
    callbackId = callbackId + 1
    local id = callbackId
    local args = {...}
    
    local p = promise.new()
    pendingCallbacks[id] = p
    
    if delay and delay > 0 then
        SetTimeout(delay, function()
            TriggerServerEvent('es_lib:callback', name, id, table.unpack(args))
        end)
    else
        TriggerServerEvent('es_lib:callback', name, id, table.unpack(args))
    end
    
    return table.unpack(Citizen.Await(p))
end

-- ============================================================================
-- REGISTER CLIENT CALLBACK (For server to call)
-- ============================================================================

---Register a callback on the client that can be triggered by the server
---@param name string The callback name
---@param cb function The callback function
local function registerCallback(name, cb)
    registeredCallbacks[name] = cb
end

-- ============================================================================
-- CREATE CALLABLE TABLE
-- ============================================================================

local callback = setmetatable({
    await = awaitCallback,
    register = registerCallback
}, {
    __call = function(_, name, delay, cb, ...)
        return triggerCallback(name, delay, cb, ...)
    end
})

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Handle response from server
RegisterNetEvent('es_lib:callbackResponse', function(id, ...)
    local cb = pendingCallbacks[id]
    
    if cb then
        pendingCallbacks[id] = nil
        
        if type(cb) == 'function' then
            cb(...)
        elseif type(cb) == 'table' and cb.resolve then
            -- It's a promise
            cb:resolve({...})
        end
    end
end)

-- Handle server calling a client callback
RegisterNetEvent('es_lib:clientCallback', function(name, id, ...)
    local cb = registeredCallbacks[name]
    
    if cb then
        local results = {cb(...)}
        TriggerServerEvent('es_lib:clientCallbackResponse', id, table.unpack(results))
    else
        TriggerServerEvent('es_lib:clientCallbackResponse', id, nil)
    end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('callback', function(name, delay, cb, ...)
    return triggerCallback(name, delay, cb, ...)
end)

exports('callbackAwait', function(name, delay, ...)
    return awaitCallback(name, delay, ...)
end)

exports('registerCallback', function(name, cb)
    return registerCallback(name, cb)
end)

-- ============================================================================
-- ATTACH TO LIB
-- ============================================================================

lib.callback = callback

return callback
