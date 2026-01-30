--[[
    Everest Lib - Shared Initialization
    Sets up the global lib table for the ecosystem
]]

lib = lib or {}

-- Resource info
lib.name = 'es_lib'
lib.context = IsDuplicityVersion() and 'server' or 'client'

-- Cache commonly used natives for performance
if lib.context == 'client' then
    lib.cache = {
        ped = PlayerPedId(),
        playerId = PlayerId(),
        serverId = GetPlayerServerId(PlayerId()),
    }
    
    -- Keep cache fresh - only update every 1 second (ped rarely changes)
    CreateThread(function()
        while true do
            Wait(1000)
            lib.cache.ped = PlayerPedId()
        end
    end)
end

return lib
