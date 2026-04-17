local floor = math.floor
local sqrt = math.sqrt
local abs = math.abs
local type = type
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local pcall = pcall

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

local function kvpGet(key, fallback)
    local value = GetResourceKvpString(key)
    if not value or value == '' then
        return fallback
    end
    return value
end

local function kvpSet(key, value)
    SetResourceKvp(key, tostring(value))
end

local function kvpGetJson(key, fallback)
    local raw = GetResourceKvpString(key)
    local decoded = safeJsonDecode(raw)
    
    if decoded == nil then
        return fallback
    end
    
    return decoded
end

local function kvpSetJson(key, data)
    SetResourceKvp(key, json.encode(data))
end

local function kvpDelete(key)
    DeleteResourceKvp(key)
end

local function distanceSquared(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return dx * dx + dy * dy + dz * dz
end

local function distanceSquaredVec(v1, v2)
    local dx = v2.x - v1.x
    local dy = v2.y - v1.y
    local dz = v2.z - v1.z
    return dx * dx + dy * dy + dz * dz
end

local function distance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return sqrt(dx * dx + dy * dy + dz * dz)
end

local function isWithinDistance(x1, y1, z1, x2, y2, z2, radius)
    return distanceSquared(x1, y1, z1, x2, y2, z2) <= (radius * radius)
end

local function isWithinDistanceVec(v1, v2, radius)
    return distanceSquaredVec(v1, v2) <= (radius * radius)
end

local function shallowCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

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

local function parseNumber(value, fallback)
    local num = tonumber(value)
    if num then
        return num
    end
    return fallback
end

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return floor(value * mult + 0.5) / mult
end

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
