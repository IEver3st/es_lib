--[[
    Everest Lib - Shared Utilities
    Optimized helper functions for common operations
]]

-- ============================================================================
-- CACHED MATH FUNCTIONS
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
local function safeJsonDecode(value)
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
local function safeJsonEncode(data)
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
local function kvpGet(key, fallback)
    local value = GetResourceKvpString(key)
    if not value or value == '' then
        return fallback
    end
    return value
end

---Set a string in KVP storage
---@param key string The KVP key
---@param value string The value to store
local function kvpSet(key, value)
    SetResourceKvp(key, tostring(value))
end

---Get a JSON-decoded table from KVP storage
---@param key string The KVP key
---@param fallback? table Default value if not found or invalid
---@return table|nil
local function kvpGetJson(key, fallback)
    local raw = GetResourceKvpString(key)
    local decoded = safeJsonDecode(raw)
    
    if decoded == nil then
        return fallback
    end
    
    return decoded
end

---Set a JSON-encoded table in KVP storage
---@param key string The KVP key
---@param data table The table to store
local function kvpSetJson(key, data)
    SetResourceKvp(key, json.encode(data))
end

---Delete a KVP key
---@param key string The KVP key to delete
local function kvpDelete(key)
    DeleteResourceKvp(key)
end

-- ============================================================================
-- DISTANCE UTILITIES
-- ============================================================================

---Calculate squared distance between two points
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number The squared distance
local function distanceSquared(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return dx * dx + dy * dy + dz * dz
end

---Calculate squared distance between two vectors
---@param v1 vector3
---@param v2 vector3
---@return number The squared distance
local function distanceSquaredVec(v1, v2)
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
local function distance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return sqrt(dx * dx + dy * dy + dz * dz)
end

---Check if a point is within radius of another
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param radius number The maximum distance
---@return boolean
local function isWithinDistance(x1, y1, z1, x2, y2, z2, radius)
    return distanceSquared(x1, y1, z1, x2, y2, z2) <= (radius * radius)
end

---Check if a vector is within radius of another
---@param v1 vector3
---@param v2 vector3
---@param radius number
---@return boolean
local function isWithinDistanceVec(v1, v2, radius)
    return distanceSquaredVec(v1, v2) <= (radius * radius)
end

-- ============================================================================
-- TABLE UTILITIES
-- ============================================================================

---Shallow copy a table
---@param t table The table to copy
---@return table
local function shallowCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

---Merge settings with defaults
---@param defaults table The default values
---@param overrides table|nil The override values
---@return table
local function mergeDefaults(defaults, overrides)
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
local function parseNumber(value, fallback)
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
local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

---Round a number to specified decimal places
---@param value number
---@param decimals? number Default 0
---@return number
local function round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return floor(value * mult + 0.5) / mult
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('safeJsonDecode', safeJsonDecode)
exports('safeJsonEncode', safeJsonEncode)
exports('kvpGet', kvpGet)
exports('kvpSet', kvpSet)
exports('kvpGetJson', kvpGetJson)
exports('kvpSetJson', kvpSetJson)
exports('kvpDelete', kvpDelete)
exports('distanceSquared', distanceSquared)
exports('distanceSquaredVec', distanceSquaredVec)
exports('distance', distance)
exports('isWithinDistance', isWithinDistance)
exports('isWithinDistanceVec', isWithinDistanceVec)
exports('shallowCopy', shallowCopy)
exports('mergeDefaults', mergeDefaults)
exports('parseNumber', parseNumber)
exports('clamp', clamp)
exports('round', round)

-- ============================================================================
-- ATTACH TO LIB
-- ============================================================================

lib.safeJsonDecode = safeJsonDecode
lib.safeJsonEncode = safeJsonEncode
lib.kvpGet = kvpGet
lib.kvpSet = kvpSet
lib.kvpGetJson = kvpGetJson
lib.kvpSetJson = kvpSetJson
lib.kvpDelete = kvpDelete
lib.distanceSquared = distanceSquared
lib.distanceSquaredVec = distanceSquaredVec
lib.distance = distance
lib.isWithinDistance = isWithinDistance
lib.isWithinDistanceVec = isWithinDistanceVec
lib.shallowCopy = shallowCopy
lib.mergeDefaults = mergeDefaults
lib.parseNumber = parseNumber
lib.clamp = clamp
lib.round = round

return {
    safeJsonDecode = safeJsonDecode,
    safeJsonEncode = safeJsonEncode,
    kvpGet = kvpGet,
    kvpSet = kvpSet,
    kvpGetJson = kvpGetJson,
    kvpSetJson = kvpSetJson,
    kvpDelete = kvpDelete,
    distanceSquared = distanceSquared,
    distanceSquaredVec = distanceSquaredVec,
    distance = distance,
    isWithinDistance = isWithinDistance,
    isWithinDistanceVec = isWithinDistanceVec,
    shallowCopy = shallowCopy,
    mergeDefaults = mergeDefaults,
    parseNumber = parseNumber,
    clamp = clamp,
    round = round
}
