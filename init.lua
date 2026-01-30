--[[
    Everest Lib - External Loader
    
    Include in other resources via:
        shared_script '@es_lib/init.lua'
    
    This provides the `lib` and `cache` globals which lazy-load modules
    when accessed (e.g., lib.notify, lib.callback, lib.zones).
    
    Based on ox_lib's module pattern for lazy loading.
]]

if not _VERSION:find('5.4') then
    error('^1[es_lib] Lua 5.4 is required. Add `lua54 \'yes\'` to your fxmanifest.lua^0')
end

local es_lib = 'es_lib'

-- Check that es_lib is started
if GetResourceState(es_lib) ~= 'started' then
    error('^1[es_lib] es_lib must be started before this resource^0')
end

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
        -- Module doesn't exist - return nil (don't cache so we don't break future attempts)
        return nil
    end
    
    -- Load and execute the module
    local fn, err = load(chunk, ('@@es_lib/imports/%s/%s.lua'):format(moduleName, context))
    
    if not fn then
        error(('^1[es_lib] Error loading module %s: %s^0'):format(moduleName, err))
    end
    
    -- Execute and get result
    local result = fn()
    
    -- If module returns a table/function, cache it
    -- If it returns nil, store a marker so we know it loaded
    if result ~= nil then
        rawset(self, moduleName, result)
    else
        rawset(self, moduleName, function() end) -- noop marker
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
-- UTILITY: Ensure a module is loaded before proceeding
-- ============================================================================

---Ensure a module is loaded (useful for dependencies)
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
-- RESOURCE-LOCAL MODULE LOADER (lib.require)
-- ============================================================================

lib._moduleCache = lib._moduleCache or {}

---Load a Lua module from the current resource (not es_lib).
---Similar to ox_lib's require, for loading resource-local modules.
---@param modulePath string Dotted module path (e.g. "modules.utility.shared.minimap")
---@return any
function lib.require(modulePath)
    local resource = GetCurrentResourceName()
    local cacheKey = resource .. ':' .. modulePath

    if lib._moduleCache[cacheKey] ~= nil then
        return lib._moduleCache[cacheKey]
    end

    local filePath = modulePath:gsub('%.', '/') .. '.lua'
    local code = LoadResourceFile(resource, filePath)
    if not code then
        error(('lib.require: missing module "%s" (%s) in %s'):format(modulePath, filePath, resource))
    end

    local chunk, err = load(code, ('@%s/%s'):format(resource, filePath), 't', _ENV)
    if not chunk then
        error(('lib.require: compile error in "%s": %s'):format(filePath, err))
    end

    local result = chunk()
    if result == nil then
        result = true
    end

    lib._moduleCache[cacheKey] = result
    return result
end

return lib
