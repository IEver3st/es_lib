local pendingCallbacks = {}
local callbackTimestamps = {}
local callbackId = 0
local registeredCallbacks = {}
local CALLBACK_TIMEOUT = 30000

local function createCallbackToken(id, source)
    return ('%s:%s:%s'):format(id, source or 0, GetGameTimer())
end

local function resolvePendingCallback(id, ...)
    local entry = pendingCallbacks[id]
    if not entry then
        return false
    end

    pendingCallbacks[id] = nil
    callbackTimestamps[id] = nil

    local cb = entry.cb

    if type(cb) == 'function' then
        cb(...)
    elseif type(cb) == 'table' and cb.resolve then
        cb:resolve({ ... })
    end

    return true
end

local function triggerCallback(name, source, cb, ...)
    callbackId = callbackId + 1
    local id = callbackId
    local token = createCallbackToken(id, source)

    if cb ~= nil then
        pendingCallbacks[id] = {
            cb = cb,
            source = source,
            token = token,
        }
        callbackTimestamps[id] = GetGameTimer()
    end

    TriggerClientEvent('es_lib:clientCallback', source, name, id, token, ...)
end

local function awaitCallback(name, source, ...)
    callbackId = callbackId + 1
    local id = callbackId
    local token = createCallbackToken(id, source)
    local p = promise.new()
    pendingCallbacks[id] = {
        cb = p,
        source = source,
        token = token,
    }
    callbackTimestamps[id] = GetGameTimer()

    TriggerClientEvent('es_lib:clientCallback', source, name, id, token, ...)

    return table.unpack(Citizen.Await(p))
end

local function registerCallback(name, cb)
    registeredCallbacks[name] = cb
end

local callback = setmetatable({
    await = awaitCallback,
    register = registerCallback
}, {
    __call = function(_, name, source, cb, ...)
        return triggerCallback(name, source, cb, ...)
    end
})

RegisterNetEvent('es_lib:callback', function(name, id, ...)
    local source = source
    local cb = registeredCallbacks[name]
    
    if cb then
        local results = {cb(source, ...)}
        TriggerClientEvent('es_lib:callbackResponse', source, id, table.unpack(results))
    end
end)

RegisterNetEvent('es_lib:clientCallbackResponse', function(id, token, ...)
    local src = source
    local entry = pendingCallbacks[id]

    if entry and entry.source == src and entry.token == token then
        resolvePendingCallback(id, ...)
    end
end)

exports('callback', function(name, source, cb, ...)
    return triggerCallback(name, source, cb, ...)
end)

exports('callbackAwait', function(name, source, ...)
    return awaitCallback(name, source, ...)
end)

exports('registerCallback', function(name, cb)
    return registerCallback(name, cb)
end)

CreateThread(function()
    while true do
        Wait(10000)
        local now = GetGameTimer()
        for id, ts in pairs(callbackTimestamps) do
            if now - ts > CALLBACK_TIMEOUT then
                resolvePendingCallback(id, nil, 'timeout')
            end
        end
    end
end)

lib.callback = callback

return callback
