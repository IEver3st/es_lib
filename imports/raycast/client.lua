local StartShapeTestLosProbe = StartShapeTestLosProbe
local GetShapeTestResultIncludingMaterial = GetShapeTestResultIncludingMaterial
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local PlayerPedId = PlayerPedId
local GetVehiclePedIsIn = GetVehiclePedIsIn
local Wait = Wait

local cos = math.cos
local sin = math.sin
local rad = math.rad

local function getDefaultIgnoreEntity()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle ~= 0 then
        return vehicle
    end

    return ped
end

local function fromCoords(coords, destination, flags, ignore)
    flags = flags or 511
    ignore = ignore or getDefaultIgnoreEntity()
    
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

local function fromCamera(flags, ignore, distance)
    flags = flags or 511
    ignore = ignore or getDefaultIgnoreEntity()
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

local raycastModule = {
    fromCoords = fromCoords,
    fromCamera = fromCamera,
    cam = fromCamera
}

lib.raycast = raycastModule

return raycastModule
