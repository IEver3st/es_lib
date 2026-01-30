--[[
    Everest Lib - Entity Getter Functions
    ox_lib compatible Get functions for finding closest/nearby entities
]]

-- ============================================================================
-- CACHED NATIVES
-- ============================================================================

local GetGamePool = GetGamePool
local GetEntityCoords = GetEntityCoords
local GetActivePlayers = GetActivePlayers
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local DoesEntityExist = DoesEntityExist
local PlayerId = PlayerId
local PlayerPedId = PlayerPedId
local GetVehiclePedIsIn = GetVehiclePedIsIn
local IsPedAPlayer = IsPedAPlayer

local sqrt = math.sqrt

-- ============================================================================
-- GET CLOSEST PLAYER
-- ============================================================================

---Get the player id, ped handle, and coords of the closest player to a set of coordinates
---@param coords vector3 The coords to check from
---@param maxDistance? number The max distance to check (default 2.0)
---@param includePlayer? boolean Whether to include the current player (default false)
---@return number|nil playerId
---@return number|nil playerPed
---@return vector3|nil playerCoords
local function getClosestPlayer(coords, maxDistance, includePlayer)
    maxDistance = maxDistance or 2.0
    local maxDistSq = maxDistance * maxDistance
    local cx, cy, cz = coords.x, coords.y, coords.z
    
    local closestId = nil
    local closestPed = nil
    local closestCoords = nil
    local closestDistSq = maxDistSq
    
    local myId = PlayerId()
    local players = GetActivePlayers()
    
    for i = 1, #players do
        local playerId = players[i]
        if includePlayer or playerId ~= myId then
            local ped = GetPlayerPed(playerId)
            if DoesEntityExist(ped) then
                local pedCoords = GetEntityCoords(ped)
                local dx = pedCoords.x - cx
                local dy = pedCoords.y - cy
                local dz = pedCoords.z - cz
                local distSq = dx * dx + dy * dy + dz * dz
                
                if distSq < closestDistSq then
                    closestDistSq = distSq
                    closestId = playerId
                    closestPed = ped
                    closestCoords = pedCoords
                end
            end
        end
    end
    
    return closestId, closestPed, closestCoords
end

-- ============================================================================
-- GET CLOSEST VEHICLE
-- ============================================================================

---Get the vehicle handle and coords of the closest vehicle to a set of coordinates
---@param coords vector3 The coords to check from
---@param maxDistance? number The max distance to check (default 2.0)
---@param includePlayerVehicle? boolean Whether to include the player's current vehicle (default false)
---@return number|nil vehicle
---@return vector3|nil vehicleCoords
local function getClosestVehicle(coords, maxDistance, includePlayerVehicle)
    maxDistance = maxDistance or 2.0
    local maxDistSq = maxDistance * maxDistance
    local cx, cy, cz = coords.x, coords.y, coords.z
    
    local playerVehicle = not includePlayerVehicle and GetVehiclePedIsIn(PlayerPedId(), false) or 0
    
    local closestVehicle = nil
    local closestCoords = nil
    local closestDistSq = maxDistSq
    
    local vehicles = GetGamePool('CVehicle')
    
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if vehicle ~= playerVehicle and DoesEntityExist(vehicle) then
            local vehCoords = GetEntityCoords(vehicle)
            local dx = vehCoords.x - cx
            local dy = vehCoords.y - cy
            local dz = vehCoords.z - cz
            local distSq = dx * dx + dy * dy + dz * dz
            
            if distSq < closestDistSq then
                closestDistSq = distSq
                closestVehicle = vehicle
                closestCoords = vehCoords
            end
        end
    end
    
    return closestVehicle, closestCoords
end

-- ============================================================================
-- GET CLOSEST PED
-- ============================================================================

---Get the ped handle and coords of the closest ped to a set of coordinates
---@param coords vector3 The coords to check from
---@param maxDistance? number The max distance to check (default 2.0)
---@return number|nil ped
---@return vector3|nil pedCoords
local function getClosestPed(coords, maxDistance)
    maxDistance = maxDistance or 2.0
    local maxDistSq = maxDistance * maxDistance
    local cx, cy, cz = coords.x, coords.y, coords.z
    
    local playerPed = PlayerPedId()
    
    local closestPed = nil
    local closestCoords = nil
    local closestDistSq = maxDistSq
    
    local peds = GetGamePool('CPed')
    
    for i = 1, #peds do
        local ped = peds[i]
        if ped ~= playerPed and not IsPedAPlayer(ped) and DoesEntityExist(ped) then
            local pedCoords = GetEntityCoords(ped)
            local dx = pedCoords.x - cx
            local dy = pedCoords.y - cy
            local dz = pedCoords.z - cz
            local distSq = dx * dx + dy * dy + dz * dz
            
            if distSq < closestDistSq then
                closestDistSq = distSq
                closestPed = ped
                closestCoords = pedCoords
            end
        end
    end
    
    return closestPed, closestCoords
end

-- ============================================================================
-- GET CLOSEST OBJECT
-- ============================================================================

---Get the object handle and coords of the closest object to a set of coordinates
---@param coords vector3 The coords to check from
---@param maxDistance? number The max distance to check (default 2.0)
---@return number|nil object
---@return vector3|nil objectCoords
local function getClosestObject(coords, maxDistance)
    maxDistance = maxDistance or 2.0
    local maxDistSq = maxDistance * maxDistance
    local cx, cy, cz = coords.x, coords.y, coords.z
    
    local closestObject = nil
    local closestCoords = nil
    local closestDistSq = maxDistSq
    
    local objects = GetGamePool('CObject')
    
    for i = 1, #objects do
        local object = objects[i]
        if DoesEntityExist(object) then
            local objCoords = GetEntityCoords(object)
            local dx = objCoords.x - cx
            local dy = objCoords.y - cy
            local dz = objCoords.z - cz
            local distSq = dx * dx + dy * dy + dz * dz
            
            if distSq < closestDistSq then
                closestDistSq = distSq
                closestObject = object
                closestCoords = objCoords
            end
        end
    end
    
    return closestObject, closestCoords
end

-- ============================================================================
-- GET NEARBY PLAYERS
-- ============================================================================

---Get the player id, ped handle, and coords of all players within range of a set of coordinates
---@param coords vector3 The coords to check from
---@param maxDistance? number The max distance to check (default 2.0)
---@param includePlayer? boolean Whether to include the current player (default false)
---@return table players Array of {id: number, ped: number, coords: vector3}
local function getNearbyPlayers(coords, maxDistance, includePlayer)
    maxDistance = maxDistance or 2.0
    local maxDistSq = maxDistance * maxDistance
    local cx, cy, cz = coords.x, coords.y, coords.z
    
    local myId = PlayerId()
    local players = GetActivePlayers()
    local nearby = {}
    local count = 0
    
    for i = 1, #players do
        local playerId = players[i]
        if includePlayer or playerId ~= myId then
            local ped = GetPlayerPed(playerId)
            if DoesEntityExist(ped) then
                local pedCoords = GetEntityCoords(ped)
                local dx = pedCoords.x - cx
                local dy = pedCoords.y - cy
                local dz = pedCoords.z - cz
                local distSq = dx * dx + dy * dy + dz * dz
                
                if distSq <= maxDistSq then
                    count = count + 1
                    nearby[count] = {
                        id = playerId,
                        ped = ped,
                        coords = pedCoords
                    }
                end
            end
        end
    end
    
    return nearby
end

-- ============================================================================
-- GET NEARBY VEHICLES
-- ============================================================================

---Get the vehicle handle and coords of all vehicles within range of a set of coordinates
---@param coords vector3 The coords to check from
---@param maxDistance? number The max distance to check (default 2.0)
---@param includePlayerVehicle? boolean Whether to include the player's current vehicle (default false)
---@return table vehicles Array of {vehicle: number, coords: vector3}
local function getNearbyVehicles(coords, maxDistance, includePlayerVehicle)
    maxDistance = maxDistance or 2.0
    local maxDistSq = maxDistance * maxDistance
    local cx, cy, cz = coords.x, coords.y, coords.z
    
    local playerVehicle = not includePlayerVehicle and GetVehiclePedIsIn(PlayerPedId(), false) or 0
    
    local vehicles = GetGamePool('CVehicle')
    local nearby = {}
    local count = 0
    
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if vehicle ~= playerVehicle and DoesEntityExist(vehicle) then
            local vehCoords = GetEntityCoords(vehicle)
            local dx = vehCoords.x - cx
            local dy = vehCoords.y - cy
            local dz = vehCoords.z - cz
            local distSq = dx * dx + dy * dy + dz * dz
            
            if distSq <= maxDistSq then
                count = count + 1
                nearby[count] = {
                    vehicle = vehicle,
                    coords = vehCoords
                }
            end
        end
    end
    
    return nearby
end

-- ============================================================================
-- GET NEARBY PEDS
-- ============================================================================

---Get the ped handle and coords of all peds within range of a set of coordinates
---@param coords vector3 The coords to check from
---@param maxDistance? number The max distance to check (default 2.0)
---@return table peds Array of {ped: number, coords: vector3}
local function getNearbyPeds(coords, maxDistance)
    maxDistance = maxDistance or 2.0
    local maxDistSq = maxDistance * maxDistance
    local cx, cy, cz = coords.x, coords.y, coords.z
    
    local playerPed = PlayerPedId()
    
    local peds = GetGamePool('CPed')
    local nearby = {}
    local count = 0
    
    for i = 1, #peds do
        local ped = peds[i]
        if ped ~= playerPed and not IsPedAPlayer(ped) and DoesEntityExist(ped) then
            local pedCoords = GetEntityCoords(ped)
            local dx = pedCoords.x - cx
            local dy = pedCoords.y - cy
            local dz = pedCoords.z - cz
            local distSq = dx * dx + dy * dy + dz * dz
            
            if distSq <= maxDistSq then
                count = count + 1
                nearby[count] = {
                    ped = ped,
                    coords = pedCoords
                }
            end
        end
    end
    
    return nearby
end

-- ============================================================================
-- GET NEARBY OBJECTS
-- ============================================================================

---Get the object handle and coords of all objects within range of a set of coordinates
---@param coords vector3 The coords to check from
---@param maxDistance? number The max distance to check (default 2.0)
---@return table objects Array of {object: number, coords: vector3}
local function getNearbyObjects(coords, maxDistance)
    maxDistance = maxDistance or 2.0
    local maxDistSq = maxDistance * maxDistance
    local cx, cy, cz = coords.x, coords.y, coords.z
    
    local objects = GetGamePool('CObject')
    local nearby = {}
    local count = 0
    
    for i = 1, #objects do
        local object = objects[i]
        if DoesEntityExist(object) then
            local objCoords = GetEntityCoords(object)
            local dx = objCoords.x - cx
            local dy = objCoords.y - cy
            local dz = objCoords.z - cz
            local distSq = dx * dx + dy * dy + dz * dz
            
            if distSq <= maxDistSq then
                count = count + 1
                nearby[count] = {
                    object = object,
                    coords = objCoords
                }
            end
        end
    end
    
    return nearby
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('getClosestPlayer', getClosestPlayer)
exports('getClosestVehicle', getClosestVehicle)
exports('getClosestPed', getClosestPed)
exports('getClosestObject', getClosestObject)
exports('getNearbyPlayers', getNearbyPlayers)
exports('getNearbyVehicles', getNearbyVehicles)
exports('getNearbyPeds', getNearbyPeds)
exports('getNearbyObjects', getNearbyObjects)

-- ============================================================================
-- ATTACH TO LIB
-- ============================================================================

lib.getClosestPlayer = getClosestPlayer
lib.getClosestVehicle = getClosestVehicle
lib.getClosestPed = getClosestPed
lib.getClosestObject = getClosestObject
lib.getNearbyPlayers = getNearbyPlayers
lib.getNearbyVehicles = getNearbyVehicles
lib.getNearbyPeds = getNearbyPeds
lib.getNearbyObjects = getNearbyObjects

return {
    getClosestPlayer = getClosestPlayer,
    getClosestVehicle = getClosestVehicle,
    getClosestPed = getClosestPed,
    getClosestObject = getClosestObject,
    getNearbyPlayers = getNearbyPlayers,
    getNearbyVehicles = getNearbyVehicles,
    getNearbyPeds = getNearbyPeds,
    getNearbyObjects = getNearbyObjects
}
