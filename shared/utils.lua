--[[
    Everest Lib - Shared Utilities
    Optimized helper functions for common operations
    
    Performance focus:
    - Cache math functions locally
    - Avoid table allocations in hot paths
    - Use squared distance where possible
]]

lib = lib or {}

-- ============================================================================
-- CACHED MATH FUNCTIONS (avoid global lookups)
-- ============================================================================

local floor = math.floor
local sqrt = math.sqrt
local abs = math.abs
local type = type
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local pcall = pcall

-- ============================================================================
-- JSON UTILITIES
-- ============================================================================

---Safely decode JSON with error handling
---@param value string|nil The JSON string to decode
---@return table|nil The decoded table or nil on failure
function lib.safeJsonDecode(value)
    if not value or value == '' then
        return nil
    end

    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then
        return decoded
    end

    return nil
end

---Safely encode a table to JSON
---@param data table The table to encode
---@return string The JSON string
function lib.safeJsonEncode(data)
    if type(data) ~= 'table' then
        return '{}'
    end
    
    local ok, encoded = pcall(json.encode, data)
    if ok then
        return encoded
    end
    
    return '{}'
end

-- ============================================================================
-- KVP UTILITIES (Key-Value Pair storage)
-- ============================================================================

---Get a string from KVP storage
---@param key string The KVP key
---@param fallback? string Default value if not found
---@return string|nil
function lib.kvpGet(key, fallback)
    local value = GetResourceKvpString(key)
    if not value or value == '' then
        return fallback
    end
    return value
end

---Set a string in KVP storage
---@param key string The KVP key
---@param value string The value to store
function lib.kvpSet(key, value)
    SetResourceKvp(key, tostring(value))
end

---Get a JSON-decoded table from KVP storage
---@param key string The KVP key
---@param fallback? table Default value if not found or invalid
---@return table|nil
function lib.kvpGetJson(key, fallback)
    local raw = GetResourceKvpString(key)
    local decoded = lib.safeJsonDecode(raw)
    
    if decoded == nil then
        return fallback
    end
    
    return decoded
end

---Set a JSON-encoded table in KVP storage
---@param key string The KVP key
---@param data table The table to store
function lib.kvpSetJson(key, data)
    SetResourceKvp(key, json.encode(data))
end

---Delete a KVP key
---@param key string The KVP key to delete
function lib.kvpDelete(key)
    DeleteResourceKvp(key)
end

-- ============================================================================
-- DISTANCE UTILITIES
-- ============================================================================

---Calculate squared distance between two points (faster than regular distance)
---Use this when you only need to compare distances, not get exact values
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number The squared distance
function lib.distanceSquared(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return dx * dx + dy * dy + dz * dz
end

---Calculate squared distance between two vectors
---@param v1 vector3
---@param v2 vector3
---@return number The squared distance
function lib.distanceSquaredVec(v1, v2)
    local dx = v2.x - v1.x
    local dy = v2.y - v1.y
    local dz = v2.z - v1.z
    return dx * dx + dy * dy + dz * dz
end

---Calculate actual distance between two points
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number The distance
function lib.distance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return sqrt(dx * dx + dy * dy + dz * dz)
end

---Check if a point is within radius of another (uses squared distance internally)
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param radius number The maximum distance
---@return boolean
function lib.isWithinDistance(x1, y1, z1, x2, y2, z2, radius)
    return lib.distanceSquared(x1, y1, z1, x2, y2, z2) <= (radius * radius)
end

---Check if a vector is within radius of another
---@param v1 vector3
---@param v2 vector3
---@param radius number
---@return boolean
function lib.isWithinDistanceVec(v1, v2, radius)
    return lib.distanceSquaredVec(v1, v2) <= (radius * radius)
end

-- ============================================================================
-- TABLE UTILITIES
-- ============================================================================

---Shallow copy a table (faster than deep copy)
---@param t table The table to copy
---@return table
function lib.shallowCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

---Merge settings with defaults (shallow merge)
---@param defaults table The default values
---@param overrides table|nil The override values
---@return table
function lib.mergeDefaults(defaults, overrides)
    local merged = {}
    for key, value in pairs(defaults) do
        merged[key] = value
    end
    if overrides then
        for key, value in pairs(overrides) do
            merged[key] = value
        end
    end
    return merged
end

-- ============================================================================
-- NUMBER UTILITIES
-- ============================================================================

---Safely parse a number with optional fallback
---@param value any The value to parse
---@param fallback? number Default value if parsing fails
---@return number|nil
function lib.parseNumber(value, fallback)
    local num = tonumber(value)
    if num then
        return num
    end
    return fallback
end

---Clamp a number between min and max
---@param value number
---@param min number
---@param max number
---@return number
function lib.clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

---Round a number to specified decimal places
---@param value number
---@param decimals? number Default 0
---@return number
function lib.round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return floor(value * mult + 0.5) / mult
end

-- ============================================================================
-- WAIT FOR UTILITY
-- ============================================================================

---Repeatedly check a condition until it returns a truthy value or times out
---@param cb function The callback that returns a truthy value when done
---@param errorMessage? string Error message if timeout occurs
---@param timeout? number Timeout in milliseconds (default 1000)
---@return any The truthy value returned by the callback, or nil on timeout
function lib.waitFor(cb, errorMessage, timeout)
    timeout = timeout or 1000
    local value = cb()
    
    if value ~= nil then
        return value
    end
    
    local start = GetGameTimer and GetGameTimer() or os.time() * 1000
    
    while value == nil do
        local elapsed = (GetGameTimer and GetGameTimer() or os.time() * 1000) - start
        
        if elapsed > timeout then
            if errorMessage then
                error(errorMessage)
            end
            return nil
        end
        
        if Wait then
            Wait(0)
        end
        
        value = cb()
    end
    
    return value
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

-- JSON
exports('safeJsonDecode', lib.safeJsonDecode)
exports('safeJsonEncode', lib.safeJsonEncode)

-- KVP
exports('kvpGet', lib.kvpGet)
exports('kvpSet', lib.kvpSet)
exports('kvpGetJson', lib.kvpGetJson)
exports('kvpSetJson', lib.kvpSetJson)
exports('kvpDelete', lib.kvpDelete)

-- Distance
exports('distanceSquared', lib.distanceSquared)
exports('distanceSquaredVec', lib.distanceSquaredVec)
exports('distance', lib.distance)
exports('isWithinDistance', lib.isWithinDistance)
exports('isWithinDistanceVec', lib.isWithinDistanceVec)

-- Table
exports('shallowCopy', lib.shallowCopy)
exports('mergeDefaults', lib.mergeDefaults)

-- Number
exports('parseNumber', lib.parseNumber)
exports('clamp', lib.clamp)
exports('round', lib.round)

-- Async
exports('waitFor', lib.waitFor)

return lib
