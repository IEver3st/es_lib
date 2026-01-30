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
local function notify(source, data)
    if type(data) == 'string' then
        data = { description = data }
    end
    TriggerClientEvent('es_lib:notify', source, data)
end

---Send notification to all players
---@param data NotifyData|string
local function notifyAll(data)
    if type(data) == 'string' then
        data = { description = data }
    end
    TriggerClientEvent('es_lib:notify', -1, data)
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('notify', notify)
exports('notifyAll', notifyAll)

-- Compatibility export with capital N and (source, type, message, duration) signature
exports('Notify', function(source, notifyType, message, duration)
    notify(source, {
        type = notifyType or 'info',
        description = message or '',
        duration = duration or 3000
    })
end)

-- ============================================================================
-- ATTACH TO LIB
-- ============================================================================

lib.notify = notify
lib.notifyAll = notifyAll

return notify
