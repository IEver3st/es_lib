lib = lib or {}

local registeredApps = {}
local pendingCallbacks = {}
local callbackId = 0

local function getRegisteredApps()
    local apps = {}
    for appId, _ in pairs(registeredApps) do
        apps[#apps + 1] = appId
    end
    return apps
end

function lib.registerUiApp(id, resourceName)
    if not id then 
        print('[es_lib] registerUiApp failed: no id provided')
        return false 
    end
    
    local ownerResource = resourceName or GetInvokingResource() or 'unknown'
    
    registeredApps[id] = {
        resource = ownerResource
    }
    print('[es_lib] Registered UI app: ' .. id .. ' (owner: ' .. ownerResource .. ')')
    return true
end

function lib.openUiApp(id, payload, opts)
    if not id then return false end

    SendNUIMessage({
        action = 'uiAppOpen',
        data = {
            id = id,
            payload = payload or {}
        }
    })

    local focus = opts and opts.focus ~= false
    local keepInput = opts and opts.keepInput or false

    if focus then
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(keepInput)
    end

    return true
end

function lib.updateUiApp(id, payload)
    if not id then return false end

    SendNUIMessage({
        action = 'uiAppData',
        data = {
            id = id,
            payload = payload or {}
        }
    })

    return true
end

function lib.closeUiApp(id)
    if not id then return false end

    SendNUIMessage({
        action = 'uiAppClose',
        data = { id = id }
    })

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    CreateThread(function()
        Wait(0)
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end)

    return true
end

function lib.respondToUiEvent(cbId, result)
    local pending = pendingCallbacks[cbId]
    if not pending then
        print('[es_lib] No pending callback for id: ' .. tostring(cbId))
        return
    end
    
    pendingCallbacks[cbId] = nil
    
    if type(result) == 'table' then
        result.ok = result.ok ~= false
        pending.cb(result)
    else
        pending.cb({ ok = true })
    end
end

RegisterNUICallback('eslib:uiEvent', function(data, cb)
    local appId = data and data.appId
    local eventType = data and data.type
    local payload = data and data.payload or {}

    if not appId then
        cb({ ok = false, error = 'missing_app' })
        return
    end

    local appInfo = registeredApps[appId]
    if not appInfo then
        print('[es_lib] No app registered: ' .. tostring(appId))
        print('[es_lib] Registered apps: ' .. table.concat(getRegisteredApps(), ', '))
        cb({ ok = false, error = 'no_handler' })
        return
    end

    callbackId = callbackId + 1
    local cbId = callbackId
    
    pendingCallbacks[cbId] = {
        cb = cb,
        appId = appId,
        timestamp = GetGameTimer()
    }
    
    TriggerEvent('eslib:uiAppEvent', appId, eventType, payload, cbId)
    
    SetTimeout(10000, function()
        if pendingCallbacks[cbId] then
            print('[es_lib] UI event timeout for app: ' .. appId .. ' event: ' .. tostring(eventType))
            pendingCallbacks[cbId].cb({ ok = false, error = 'timeout' })
            pendingCallbacks[cbId] = nil
        end
    end)
end)

exports('registerUiApp', lib.registerUiApp)
exports('openUiApp', lib.openUiApp)
exports('updateUiApp', lib.updateUiApp)
exports('closeUiApp', lib.closeUiApp)
exports('respondToUiEvent', lib.respondToUiEvent)

RegisterCommand('eslib_apps', function()
    local apps = getRegisteredApps()
    if #apps == 0 then
        print('[es_lib] No UI apps registered')
    else
        print('[es_lib] Registered UI apps: ' .. table.concat(apps, ', '))
    end
end, false)

return lib
