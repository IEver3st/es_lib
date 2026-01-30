--[[
    Everest Lib - Server Notification System
    Send notifications to players from server-side
]]

---@class NotifyData
---@field id? string
---@field title? string
---@field description? string
---@field duration? number
---@field position? string
---@field type? string
---@field showDuration? boolean

---Send notification to a specific player
---@param source number|string Player server ID
---@param data NotifyData|string
function lib.notify(source, data)
    if type(data) == 'string' then
        data = { description = data }
    end
    TriggerClientEvent('es_lib:notify', source, data)
end

---Send notification to all players
---@param data NotifyData|string
function lib.notifyAll(data)
    if type(data) == 'string' then
        data = { description = data }
    end
    TriggerClientEvent('es_lib:notify', -1, data)
end

-- Export for other resources
exports('notify', lib.notify)
exports('notifyAll', lib.notifyAll)

-- Compatibility export with capital N and (source, type, message, duration) signature
-- Used by resources expecting this format
exports('Notify', function(source, notifyType, message, duration)
    lib.notify(source, {
        type = notifyType or 'info',
        description = message or '',
        duration = duration or 3000
    })
end)

return lib
