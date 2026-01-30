--[[
    Everest Lib - Points Module
    ox_lib compatible points system for distance-based callbacks
]]

-- ============================================================================
-- CACHED NATIVES
-- ============================================================================

local GetEntityCoords = GetEntityCoords
local PlayerPedId = PlayerPedId
local Wait = Wait

local sqrt = math.sqrt

-- ============================================================================
-- POINT STORAGE
-- ============================================================================

local points = {}
local pointId = 0
local nearbyPoints = {}
local closestPoint = nil

-- ============================================================================
-- CPOINT CLASS
-- ============================================================================

local CPoint = {}
CPoint.__index = CPoint

---Remove the point from the registry
function CPoint:remove()
    points[self.id] = nil
    
    for i = #nearbyPoints, 1, -1 do
        if nearbyPoints[i].id == self.id then
            table.remove(nearbyPoints, i)
            break
        end
    end
    
    if closestPoint and closestPoint.id == self.id then
        closestPoint = nil
    end
end

-- ============================================================================
-- CREATE NEW POINT
-- ============================================================================

---Create a new point
---@param data table Point configuration
---@return table point The CPoint object
local function new(data)
    pointId = pointId + 1
    
    local coords = data.coords
    if not coords then
        error('lib.points.new requires coords')
    end
    
    local distance = data.distance or 5.0
    
    local point = setmetatable({
        id = pointId,
        coords = coords,
        distance = distance,
        currentDistance = math.huge,
        isClosest = false,
        _wasNearby = false
    }, CPoint)
    
    for k, v in pairs(data) do
        if k ~= 'coords' and k ~= 'distance' then
            point[k] = v
        end
    end
    
    points[pointId] = point
    return point
end

-- ============================================================================
-- GET ALL POINTS
-- ============================================================================

---Get a table of all points created in the resource
---@return table points Array of CPoint objects
local function getAllPoints()
    local result = {}
    local count = 0
    
    for _, point in pairs(points) do
        count = count + 1
        result[count] = point
    end
    
    return result
end

-- ============================================================================
-- GET NEARBY POINTS
-- ============================================================================

---Get an array of all points in range of the player
---@return table nearbyPoints Array of CPoint objects
local function getNearbyPoints()
    return nearbyPoints
end

-- ============================================================================
-- GET CLOSEST POINT
-- ============================================================================

---Get the data for the closest point to the player
---@return table|nil closestPoint The closest CPoint or nil
local function getClosestPoint()
    return closestPoint
end

-- ============================================================================
-- POINT TICK HANDLER
-- ============================================================================

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local px, py, pz = playerCoords.x, playerCoords.y, playerCoords.z
        
        nearbyPoints = {}
        local nearbyCount = 0
        closestPoint = nil
        local closestDistSq = math.huge
        
        for id, point in pairs(points) do
            local coords = point.coords
            local dx = coords.x - px
            local dy = coords.y - py
            local dz = coords.z - pz
            local distSq = dx * dx + dy * dy + dz * dz
            local dist = sqrt(distSq)
            
            point.currentDistance = dist
            point.isClosest = false
            
            local isNearby = dist <= point.distance
            local wasNearby = point._wasNearby
            
            if distSq < closestDistSq then
                closestDistSq = distSq
                closestPoint = point
            end
            
            if isNearby and not wasNearby then
                if point.onEnter then
                    point:onEnter()
                end
            end
            
            if not isNearby and wasNearby then
                if point.onExit then
                    point:onExit()
                end
            end
            
            point._wasNearby = isNearby
            
            if isNearby then
                nearbyCount = nearbyCount + 1
                nearbyPoints[nearbyCount] = point
            end
        end
        
        if closestPoint then
            closestPoint.isClosest = true
        end
        
        Wait(100)
    end
end)

-- ============================================================================
-- NEARBY CALLBACK HANDLER
-- ============================================================================

CreateThread(function()
    while true do
        for i = 1, #nearbyPoints do
            local point = nearbyPoints[i]
            if point and point.nearby then
                point:nearby()
            end
        end
        
        Wait(0)
    end
end)

-- ============================================================================
-- POINTS MODULE
-- ============================================================================

local pointsModule = {
    new = new,
    getAllPoints = getAllPoints,
    getNearbyPoints = getNearbyPoints,
    getClosestPoint = getClosestPoint
}

-- ============================================================================
-- ATTACH TO LIB
-- ============================================================================

lib.points = pointsModule

return pointsModule
