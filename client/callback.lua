lib = lib or {}

local pendingCallbacks = {}
local callbackId = 0
local registeredCallbacks = {}

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

local function registerCallback(name, cb)
    registeredCallbacks[name] = cb
end

lib.callback = setmetatable({
    await = awaitCallback,
    register = registerCallback
}, {
    __call = function(_, name, delay, cb, ...)
        return triggerCallback(name, delay, cb, ...)
    end
})

RegisterNetEvent('es_lib:callbackResponse', function(id, ...)
    local cb = pendingCallbacks[id]
    
    if cb then
        pendingCallbacks[id] = nil
        
        if type(cb) == 'function' then
            cb(...)
        elseif type(cb) == 'table' and cb.resolve then
            cb:resolve({...})
        end
    end
end)

RegisterNetEvent('es_lib:clientCallback', function(name, id, ...)
    local cb = registeredCallbacks[name]
    
    if cb then
        local results = {cb(...)}
        TriggerServerEvent('es_lib:clientCallbackResponse', id, table.unpack(results))
    else
        TriggerServerEvent('es_lib:clientCallbackResponse', id, nil)
    end
end)

exports('callback', function(name, delay, cb, ...)
    return triggerCallback(name, delay, cb, ...)
end)

exports('callbackAwait', function(name, delay, ...)
    return awaitCallback(name, delay, ...)
end)

exports('registerCallback', function(name, cb)
    return registerCallback(name, cb)
end)

return lib
