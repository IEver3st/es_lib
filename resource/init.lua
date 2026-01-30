--[[
    Everest Lib - Internal Resource Initialization
    
    This file initializes es_lib for internal use within the resource itself.
    It sets up the same lazy-loading lib table but for es_lib's own scripts.
]]

local es_lib = 'es_lib'
local context = IsDuplicityVersion() and 'server' or 'client'

-- ============================================================================
-- CACHE SYSTEM (Client-side player data caching)
-- ============================================================================

local cache = {}

if context == 'client' then
    cache = setmetatable({
        ped = 0,
        playerId = -1,
        serverId = -1,
        vehicle = 0,
        seat = -1,
    }, {
        __index = function(self, key)
            return rawget(self, key)
        end,
        __newindex = function(self, key, value)
            rawset(self, key, value)
        end,
    })
    
    -- Initialize cache values
    CreateThread(function()
        while true do
            cache.playerId = PlayerId()
            cache.ped = PlayerPedId()
            cache.serverId = GetPlayerServerId(cache.playerId)
            
            local vehicle = GetVehiclePedIsIn(cache.ped, false)
            if vehicle ~= cache.vehicle then
                cache.vehicle = vehicle
            end
            
            if vehicle > 0 then
                for i = -1, 16 do
                    if GetPedInVehicleSeat(vehicle, i) == cache.ped then
                        cache.seat = i
                        break
                    end
                end
            else
                cache.seat = -1
            end
            
            Wait(100)
        end
    end)
end

-- ============================================================================
-- MODULE LOADER (Lazy loading via __index)
-- ============================================================================

local function loadModule(self, moduleName)
    local dir = ('imports/%s'):format(moduleName)
    
    -- Try to load context-specific file first (client.lua or server.lua)
    local chunk = LoadResourceFile(es_lib, ('%s/%s.lua'):format(dir, context))
    
    -- Also try shared.lua and prepend it if it exists
    local shared = LoadResourceFile(es_lib, ('%s/shared.lua'):format(dir))
    
    if shared then
        chunk = chunk and ('%s\n%s'):format(shared, chunk) or shared
    end
    
    if not chunk then
        return nil
    end
    
    -- Load and execute the module
    local fn, err = load(chunk, ('@@es_lib/imports/%s/%s.lua'):format(moduleName, context))
    
    if not fn then
        error(('^1[es_lib] Error loading module %s: %s^0'):format(moduleName, err))
    end
    
    -- Execute and get result
    local result = fn()
    
    -- Cache the result
    if result ~= nil then
        rawset(self, moduleName, result)
    else
        rawset(self, moduleName, function() end)
    end
    
    return rawget(self, moduleName)
end

-- ============================================================================
-- LIB TABLE SETUP
-- ============================================================================

lib = setmetatable({
    name = es_lib,
    context = context,
    cache = cache,
}, {
    __index = loadModule,
    __call = function(self, moduleName)
        return loadModule(self, moduleName)
    end,
})

-- ============================================================================
-- EXPOSE TO GLOBAL ENVIRONMENT
-- ============================================================================

_ENV.lib = lib
_ENV.cache = cache

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

---Ensure a module is loaded
---@param moduleName string
---@return any The loaded module
function lib.load(moduleName)
    if rawget(lib, moduleName) then
        return rawget(lib, moduleName)
    end
    return loadModule(lib, moduleName)
end

---Check if we're running inside es_lib resource
---@return boolean
function lib.isInternalResource()
    return GetCurrentResourceName() == es_lib
end

-- ============================================================================
-- EXPORT: hasLoaded
-- Used by other resources to check if es_lib is ready
-- ============================================================================

local hasLoadedCallbacks = {}

function lib.hasLoaded()
    return true
end

exports('hasLoaded', lib.hasLoaded)

-- Notify waiting resources
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == es_lib then
        TriggerEvent('es_lib:loaded')
    end
end)

-- ============================================================================
-- PRELOAD CORE MODULES
-- These modules attach functions directly to lib (e.g., lib.registerMenu)
-- so they need to be loaded before any scripts try to use them.
-- ============================================================================

local coreModules = {
    'settings',
    'notify',
    'menu',
    'radial',
    'callback',
    'help',
    'getters',
}

for _, moduleName in ipairs(coreModules) do
    lib.load(moduleName)
end

return lib
