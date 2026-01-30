--[[
    Everest Lib - Server Callback Module
    ox_lib compatible callback system for server-client communication
    
    Usage:
    - lib.callback(name, source, cb, ...) - Async callback to client with function
    - lib.callback.await(name, source, ...) - Synchronous callback to client
    - lib.callback.register(name, cb) - Register a server callback for client to call
]]

lib = lib or {}
lib.callback = lib.callback or {}

-- ============================================================================
-- CALLBACK STORAGE
-- ============================================================================

local pendingCallbacks = {}
local callbackId = 0
local registeredCallbacks = {}

-- ============================================================================
-- TRIGGER CLIENT CALLBACK (Async)
-- ============================================================================

---Trigger a client callback asynchronously
---@param name string The callback name registered on the client
---@param source number The player server id
---@param cb function The function to call with the result
---@vararg any Arguments to pass to the client
function lib.callback(name, source, cb, ...)
    callbackId = callbackId + 1
    local id = callbackId
    
    pendingCallbacks[id] = cb
    
    TriggerClientEvent('es_lib:clientCallback', source, name, id, ...)
end

-- Make lib.callback callable as a function
setmetatable(lib.callback, {
    __call = function(self, name, source, cb, ...)
        return lib.callback(name, source, cb, ...)
    end
})

-- ============================================================================
-- TRIGGER CLIENT CALLBACK (Sync/Await)
-- ============================================================================

---Trigger a client callback and wait for the result
---@param name string The callback name registered on the client
---@param source number The player server id
---@vararg any Arguments to pass to the client
---@return any ... The values returned by the client callback
function lib.callback.await(name, source, ...)
    callbackId = callbackId + 1
    local id = callbackId
    
    local p = promise.new()
    pendingCallbacks[id] = p
    
    TriggerClientEvent('es_lib:clientCallback', source, name, id, ...)
    
    return table.unpack(Citizen.Await(p))
end

-- ============================================================================
-- REGISTER SERVER CALLBACK (For client to call)
-- ============================================================================

---Register a callback on the server that can be triggered by the client
---@param name string The callback name
---@param cb function The callback function (receives source as first arg)
function lib.callback.register(name, cb)
    registeredCallbacks[name] = cb
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Handle client calling a server callback
RegisterNetEvent('es_lib:callback', function(name, id, ...)
    local source = source
    local cb = registeredCallbacks[name]
    
    if cb then
        local results = {cb(source, ...)}
        TriggerClientEvent('es_lib:callbackResponse', source, id, table.unpack(results))
    else
        TriggerClientEvent('es_lib:callbackResponse', source, id, nil)
    end
end)

-- Handle response from client callback
RegisterNetEvent('es_lib:clientCallbackResponse', function(id, ...)
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

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('callback', function(name, source, cb, ...)
    return lib.callback(name, source, cb, ...)
end)

exports('callbackAwait', function(name, source, ...)
    return lib.callback.await(name, source, ...)
end)

exports('registerCallback', function(name, cb)
    return lib.callback.register(name, cb)
end)

return lib
