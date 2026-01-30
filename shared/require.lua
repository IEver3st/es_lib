--[[
    Everest Lib - Lightweight module loader
    Provides lib.require similar to ox_lib for resource-local modules.
]]

lib = lib or {}

lib._moduleCache = lib._moduleCache or {}

---Load a Lua module from the current resource.
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
