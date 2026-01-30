--[[
    Everest Lib - Zones Module
    ox_lib compatible zone system with polygon, box, and sphere zones
    
    Performance focus:
    - Efficient point-in-zone checks
    - Staggered zone checking (not every frame)
    - Minimal allocations
]]

lib = lib or {}
lib.zones = lib.zones or {}

-- ============================================================================
-- CACHED NATIVES
-- ============================================================================

local GetEntityCoords = GetEntityCoords
local PlayerPedId = PlayerPedId
local DrawLine = DrawLine
local DrawPoly = DrawPoly
local Wait = Wait

local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local rad = math.rad
local abs = math.abs
local min = math.min
local max = math.max

-- ============================================================================
-- ZONE STORAGE
-- ============================================================================

local zones = {}
local zoneId = 0
local checkInterval = 250 -- Check zones every 250ms

-- ============================================================================
-- POINT IN POLYGON (2D check with height tolerance)
-- ============================================================================

local function pointInPolygon(x, y, points)
    local inside = false
    local j = #points
    
    for i = 1, #points do
        local xi, yi = points[i].x, points[i].y
        local xj, yj = points[j].x, points[j].y
        
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        
        j = i
    end
    
    return inside
end

-- ============================================================================
-- ZONE BASE METHODS
-- ============================================================================

local ZoneMethods = {}
ZoneMethods.__index = ZoneMethods

function ZoneMethods:remove()
    zones[self.id] = nil
end

-- ============================================================================
-- POLYGON ZONE
-- ============================================================================

---Create a polygon zone
---@param data table Zone configuration
---@return table zone The zone object
function lib.zones.poly(data)
    zoneId = zoneId + 1
    
    local points = data.points
    if not points or #points < 3 then
        error('lib.zones.poly requires at least 3 points')
    end
    
    -- Calculate bounding box and center for optimization
    local minX, maxX = points[1].x, points[1].x
    local minY, maxY = points[1].y, points[1].y
    local minZ, maxZ = points[1].z, points[1].z
    local sumX, sumY, sumZ = 0, 0, 0
    
    for i = 1, #points do
        local p = points[i]
        minX = min(minX, p.x)
        maxX = max(maxX, p.x)
        minY = min(minY, p.y)
        maxY = max(maxY, p.y)
        minZ = min(minZ, p.z)
        maxZ = max(maxZ, p.z)
        sumX = sumX + p.x
        sumY = sumY + p.y
        sumZ = sumZ + p.z
    end
    
    local thickness = data.thickness or 4.0
    
    local zone = setmetatable({
        id = zoneId,
        type = 'poly',
        points = points,
        thickness = thickness,
        minZ = minZ,
        maxZ = minZ + thickness,
        minX = minX,
        maxX = maxX,
        minY = minY,
        maxY = maxY,
        center = vector3(sumX / #points, sumY / #points, sumZ / #points),
        debug = data.debug or false,
        onEnter = data.onEnter,
        onExit = data.onExit,
        inside = data.inside,
        isInside = false
    }, ZoneMethods)
    
    -- Copy any custom properties
    for k, v in pairs(data) do
        if not zone[k] then
            zone[k] = v
        end
    end
    
    function zone:contains(point)
        -- Quick bounding box check first
        if point.x < self.minX or point.x > self.maxX or
           point.y < self.minY or point.y > self.maxY or
           point.z < self.minZ or point.z > self.maxZ then
            return false
        end
        
        return pointInPolygon(point.x, point.y, self.points)
    end
    
    zones[zoneId] = zone
    return zone
end

-- ============================================================================
-- BOX ZONE
-- ============================================================================

---Create a box zone
---@param data table Zone configuration
---@return table zone The zone object
function lib.zones.box(data)
    zoneId = zoneId + 1
    
    local coords = data.coords
    if not coords then
        error('lib.zones.box requires coords')
    end
    
    local size = data.size or vector3(2, 2, 2)
    local rotation = data.rotation or 0
    local rotRad = rad(rotation)
    local cosR = cos(rotRad)
    local sinR = sin(rotRad)
    
    local halfX = size.x / 2
    local halfY = size.y / 2
    local halfZ = size.z / 2
    
    local zone = setmetatable({
        id = zoneId,
        type = 'box',
        coords = coords,
        size = size,
        rotation = rotation,
        rotRad = rotRad,
        cosR = cosR,
        sinR = sinR,
        halfX = halfX,
        halfY = halfY,
        halfZ = halfZ,
        debug = data.debug or false,
        onEnter = data.onEnter,
        onExit = data.onExit,
        inside = data.inside,
        isInside = false
    }, ZoneMethods)
    
    -- Copy any custom properties
    for k, v in pairs(data) do
        if not zone[k] then
            zone[k] = v
        end
    end
    
    function zone:contains(point)
        -- Translate point relative to box center
        local dx = point.x - self.coords.x
        local dy = point.y - self.coords.y
        local dz = point.z - self.coords.z
        
        -- Rotate point to align with box axes (inverse rotation)
        local localX = dx * self.cosR + dy * self.sinR
        local localY = -dx * self.sinR + dy * self.cosR
        
        -- Check if within box bounds
        return abs(localX) <= self.halfX and
               abs(localY) <= self.halfY and
               abs(dz) <= self.halfZ
    end
    
    zones[zoneId] = zone
    return zone
end

-- ============================================================================
-- SPHERE ZONE
-- ============================================================================

---Create a sphere zone
---@param data table Zone configuration
---@return table zone The zone object
function lib.zones.sphere(data)
    zoneId = zoneId + 1
    
    local coords = data.coords
    if not coords then
        error('lib.zones.sphere requires coords')
    end
    
    local radius = data.radius or 2.0
    local radiusSq = radius * radius
    
    local zone = setmetatable({
        id = zoneId,
        type = 'sphere',
        coords = coords,
        radius = radius,
        radiusSq = radiusSq,
        debug = data.debug or false,
        onEnter = data.onEnter,
        onExit = data.onExit,
        inside = data.inside,
        isInside = false
    }, ZoneMethods)
    
    -- Copy any custom properties
    for k, v in pairs(data) do
        if not zone[k] then
            zone[k] = v
        end
    end
    
    function zone:contains(point)
        local dx = point.x - self.coords.x
        local dy = point.y - self.coords.y
        local dz = point.z - self.coords.z
        return (dx * dx + dy * dy + dz * dz) <= self.radiusSq
    end
    
    zones[zoneId] = zone
    return zone
end

-- ============================================================================
-- ZONE TICK HANDLER
-- ============================================================================

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        
        for id, zone in pairs(zones) do
            local wasInside = zone.isInside
            local isInside = zone:contains(playerCoords)
            zone.isInside = isInside
            
            if isInside and not wasInside then
                if zone.onEnter then
                    zone:onEnter()
                end
            elseif not isInside and wasInside then
                if zone.onExit then
                    zone:onExit()
                end
            end
            
            if isInside and zone.inside then
                zone:inside()
            end
        end
        
        Wait(checkInterval)
    end
end)

-- ============================================================================
-- DEBUG RENDERING
-- ============================================================================

CreateThread(function()
    while true do
        local hasDebug = false
        
        for id, zone in pairs(zones) do
            if zone.debug then
                hasDebug = true
                local color = zone.isInside and {0, 255, 0, 100} or {255, 0, 0, 100}
                
                if zone.type == 'sphere' then
                    -- Draw sphere as marker
                    DrawMarker(28, zone.coords.x, zone.coords.y, zone.coords.z, 
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                        zone.radius * 2, zone.radius * 2, zone.radius * 2, 
                        color[1], color[2], color[3], color[4], false, false, 2, false, nil, nil, false)
                        
                elseif zone.type == 'box' then
                    -- Draw box as marker with rotation
                    DrawMarker(1, zone.coords.x, zone.coords.y, zone.coords.z, 
                        0.0, 0.0, 0.0, 0.0, 0.0, zone.rotation, 
                        zone.size.x, zone.size.y, zone.size.z, 
                        color[1], color[2], color[3], color[4], false, false, 2, false, nil, nil, false)
                        
                elseif zone.type == 'poly' then
                    -- Draw polygon edges
                    local points = zone.points
                    for i = 1, #points do
                        local p1 = points[i]
                        local p2 = points[i % #points + 1]
                        DrawLine(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, color[1], color[2], color[3], 200)
                        DrawLine(p1.x, p1.y, p1.z + zone.thickness, p2.x, p2.y, p2.z + zone.thickness, color[1], color[2], color[3], 200)
                        DrawLine(p1.x, p1.y, p1.z, p1.x, p1.y, p1.z + zone.thickness, color[1], color[2], color[3], 200)
                    end
                end
            end
        end
        
        if hasDebug then
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

return lib
