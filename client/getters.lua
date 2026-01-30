lib = lib or {}

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

function lib.getClosestPlayer(coords, maxDistance, includePlayer)
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

function lib.getClosestVehicle(coords, maxDistance, includePlayerVehicle)
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

function lib.getClosestPed(coords, maxDistance)
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

function lib.getClosestObject(coords, maxDistance)
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

function lib.getNearbyPlayers(coords, maxDistance, includePlayer)
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

function lib.getNearbyVehicles(coords, maxDistance, includePlayerVehicle)
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

function lib.getNearbyPeds(coords, maxDistance)
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

function lib.getNearbyObjects(coords, maxDistance)
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

exports('getClosestPlayer', lib.getClosestPlayer)
exports('getClosestVehicle', lib.getClosestVehicle)
exports('getClosestPed', lib.getClosestPed)
exports('getClosestObject', lib.getClosestObject)
exports('getNearbyPlayers', lib.getNearbyPlayers)
exports('getNearbyVehicles', lib.getNearbyVehicles)
exports('getNearbyPeds', lib.getNearbyPeds)
exports('getNearbyObjects', lib.getNearbyObjects)

return lib
