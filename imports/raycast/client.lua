--[[
    Everest Lib - Raycast Module
    ox_lib compatible raycast functions
]]

-- ============================================================================
-- CACHED NATIVES
-- ============================================================================

local StartShapeTestLosProbe = StartShapeTestLosProbe
local GetShapeTestResultIncludingMaterial = GetShapeTestResultIncludingMaterial
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local Wait = Wait

local cos = math.cos
local sin = math.sin
local rad = math.rad

-- ============================================================================
-- RAYCAST FROM COORDS
-- ============================================================================

---Starts a shapetest originating from starting coordinates and ending at destination coordinates
---@param coords vector3 Starting coords for raycast
---@param destination vector3 Destination coords for raycast
---@param flags? number Intersection flags (default 511)
---@param ignore? number Entity to ignore (default 4)
---@return boolean hit Whether or not an entity was hit
---@return number entityHit Entity handle of hit entity
---@return vector3 endCoords Closest coords to where the raycast hit
---@return vector3 surfaceNormal Normal to the surface that was hit
---@return number materialHash Hash of the material that was hit
local function fromCoords(coords, destination, flags, ignore)
    flags = flags or 511
    ignore = ignore or 4
    
    local shapeTest = StartShapeTestLosProbe(
        coords.x, coords.y, coords.z,
        destination.x, destination.y, destination.z,
        flags, ignore, 0
    )
    
    local status, hit, endCoords, surfaceNormal, materialHash, entityHit
    
    repeat
        Wait(0)
        status, hit, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultIncludingMaterial(shapeTest)
    until status ~= 1
    
    return hit == 1, entityHit, endCoords, surfaceNormal, materialHash
end

-- ============================================================================
-- RAYCAST FROM CAMERA
-- ============================================================================

---Starts a shapetest originating from the camera, extending to a specified distance
---@param flags? number Intersection flags (default 511)
---@param ignore? number Entity to ignore (default 4)
---@param distance? number Maximum distance (default 10)
---@return boolean hit Whether or not an entity was hit
---@return number entityHit Entity handle of hit entity
---@return vector3 endCoords Closest coords to where the raycast hit
---@return vector3 surfaceNormal Normal to the surface that was hit
---@return number materialHash Hash of the material that was hit
local function fromCamera(flags, ignore, distance)
    flags = flags or 511
    ignore = ignore or 4
    distance = distance or 10.0
    
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    
    local rotZ = rad(camRot.z)
    local rotX = rad(camRot.x)
    local cosX = cos(rotX)
    
    local direction = vector3(
        -sin(rotZ) * cosX,
        cos(rotZ) * cosX,
        sin(rotX)
    )
    
    local destination = vector3(
        camCoords.x + direction.x * distance,
        camCoords.y + direction.y * distance,
        camCoords.z + direction.z * distance
    )
    
    return fromCoords(camCoords, destination, flags, ignore)
end

-- ============================================================================
-- RAYCAST MODULE
-- ============================================================================

local raycastModule = {
    fromCoords = fromCoords,
    fromCamera = fromCamera,
    cam = fromCamera -- Legacy alias
}

-- ============================================================================
-- ATTACH TO LIB
-- ============================================================================

lib.raycast = raycastModule

return raycastModule
