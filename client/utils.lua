--[[
    Everest Lib - Client Utilities
    Optimized helpers for client-side operations
    
    Performance focus:
    - Cache natives at module level
    - Use squared distance for comparisons
    - Minimize per-frame allocations
]]

lib = lib or {}

-- ============================================================================
-- CACHED NATIVES (Critical for performance)
-- ============================================================================

local PlayerPedId = PlayerPedId
local PlayerId = PlayerId
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local GetGamePool = GetGamePool
local IsEntityDead = IsEntityDead
local GetEntityHealth = GetEntityHealth
local GetEntityModel = GetEntityModel
local GetVehiclePedIsIn = GetVehiclePedIsIn

-- Math caching
local sqrt = math.sqrt

-- ============================================================================
-- ENTITY POOL UTILITIES
-- ============================================================================

---Clear entities from a pool within radius using squared distance
---@param poolName string 'CPed', 'CVehicle', or 'CObject'
---@param centerCoords vector3 Center point for clearing
---@param radius number Radius in meters
---@param excludeEntity? number Entity to exclude (usually player ped)
---@return number count Number of entities deleted
function lib.clearPool(poolName, centerCoords, radius, excludeEntity)
    local pool = GetGamePool(poolName)
    local radiusSq = radius * radius
    local cx, cy, cz = centerCoords.x, centerCoords.y, centerCoords.z
    local count = 0
    
    for i = 1, #pool do
        local entity = pool[i]
        if entity ~= excludeEntity and DoesEntityExist(entity) then
            local eCoords = GetEntityCoords(entity)
            local dx = eCoords.x - cx
            local dy = eCoords.y - cy
            local dz = eCoords.z - cz
            local distSq = dx * dx + dy * dy + dz * dz
            
            if distSq <= radiusSq then
                SetEntityAsMissionEntity(entity, true, true)
                DeleteEntity(entity)
                count = count + 1
            end
        end
    end
    
    return count
end

---Clear multiple pools at once (more efficient than calling clearPool multiple times)
---@param poolNames table Array of pool names
---@param centerCoords vector3
---@param radius number
---@param excludeEntity? number
---@return number total Total entities deleted
function lib.clearPools(poolNames, centerCoords, radius, excludeEntity)
    local total = 0
    for i = 1, #poolNames do
        total = total + lib.clearPool(poolNames[i], centerCoords, radius, excludeEntity)
    end
    return total
end

---Find nearest entity in a pool
---@param poolName string
---@param centerCoords vector3
---@param maxRadius? number Maximum search radius (default 50)
---@param excludeEntity? number
---@return number|nil entity The nearest entity or nil
---@return number distance Distance to the entity (or math.huge if none found)
function lib.findNearestInPool(poolName, centerCoords, maxRadius, excludeEntity)
    local pool = GetGamePool(poolName)
    maxRadius = maxRadius or 50.0
    local maxRadiusSq = maxRadius * maxRadius
    local cx, cy, cz = centerCoords.x, centerCoords.y, centerCoords.z
    
    local nearestEntity = nil
    local nearestDistSq = maxRadiusSq
    
    for i = 1, #pool do
        local entity = pool[i]
        if entity ~= excludeEntity and DoesEntityExist(entity) then
            local eCoords = GetEntityCoords(entity)
            local dx = eCoords.x - cx
            local dy = eCoords.y - cy
            local dz = eCoords.z - cz
            local distSq = dx * dx + dy * dy + dz * dz
            
            if distSq < nearestDistSq then
                nearestDistSq = distSq
                nearestEntity = entity
            end
        end
    end
    
    if nearestEntity then
        return nearestEntity, sqrt(nearestDistSq)
    end
    
    return nil, math.huge
end

-- ============================================================================
-- PED UTILITIES
-- ============================================================================

---Get player ped (uses cache if available, otherwise calls native)
---@return number ped
function lib.getPed()
    if lib.cache and lib.cache.ped then
        return lib.cache.ped
    end
    return PlayerPedId()
end

---Get player ID (uses cache if available)
---@return number playerId
function lib.getPlayerId()
    if lib.cache and lib.cache.playerId then
        return lib.cache.playerId
    end
    return PlayerId()
end

---Check if player is in a vehicle
---@param includeLastVehicle? boolean Include last vehicle (default false)
---@return boolean
function lib.isInVehicle(includeLastVehicle)
    local ped = lib.getPed()
    return GetVehiclePedIsIn(ped, includeLastVehicle or false) ~= 0
end

---Get current vehicle or nil
---@param includeLastVehicle? boolean
---@return number|nil
function lib.getCurrentVehicle(includeLastVehicle)
    local ped = lib.getPed()
    local vehicle = GetVehiclePedIsIn(ped, includeLastVehicle or false)
    if vehicle ~= 0 then
        return vehicle
    end
    return nil
end

---Get player coordinates
---@return vector3
function lib.getCoords()
    return GetEntityCoords(lib.getPed())
end

---Get player heading
---@return number
function lib.getHeading()
    return GetEntityHeading(lib.getPed())
end

-- ============================================================================
-- VEHICLE UTILITIES  
-- ============================================================================

---Ensure player is in a vehicle, returns vehicle or nil with optional notification
---@param showNotify? boolean Show error notification if not in vehicle
---@return number|nil vehicle
function lib.ensureVehicle(showNotify)
    local ped = lib.getPed()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        if showNotify and lib.notify then
            lib.notify({ type = 'error', description = 'You are not in a vehicle.' })
        end
        return nil
    end
    
    return vehicle
end

-- ============================================================================
-- CAMERA UTILITIES
-- ============================================================================

---Get camera direction vector (optimized)
---@return vector3 direction
function lib.getCamDirection()
    local rot = GetGameplayCamRot(2)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosX = math.cos(rotX)
    
    return vector3(
        -math.sin(rotZ) * cosX,
        math.cos(rotZ) * cosX,
        math.sin(rotX)
    )
end

-- ============================================================================
-- CLIPBOARD UTILITY
-- ============================================================================

---Copy text to clipboard via NUI
---@param text string
function lib.copyToClipboard(text)
    SendNUIMessage({
        action = 'copyToClipboard',
        data = { text = tostring(text) }
    })
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

-- Pool utilities
exports('clearPool', lib.clearPool)
exports('clearPools', lib.clearPools)
exports('findNearestInPool', lib.findNearestInPool)

-- Ped utilities
exports('getPed', lib.getPed)
exports('getPlayerId', lib.getPlayerId)
exports('isInVehicle', lib.isInVehicle)
exports('getCurrentVehicle', lib.getCurrentVehicle)
exports('getCoords', lib.getCoords)
exports('getHeading', lib.getHeading)
exports('ensureVehicle', lib.ensureVehicle)

-- Camera
exports('getCamDirection', lib.getCamDirection)

-- Clipboard
exports('copyToClipboard', lib.copyToClipboard)

return lib
