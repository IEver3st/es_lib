--[[
    Everest Lib - Timer Module
    ox_lib compatible timer utility
]]

-- ============================================================================
-- CACHED FUNCTIONS
-- ============================================================================

local GetGameTimer = GetGameTimer
local Wait = Wait

-- ============================================================================
-- TIMER CLASS
-- ============================================================================

local Timer = {}
Timer.__index = Timer

---Create a new timer
---@param duration number Duration in milliseconds
---@param onEnd function Callback when timer ends
---@param async? boolean Whether to run asynchronously (default true)
---@return table Timer instance
local function timer(duration, onEnd, async)
    if async == nil then async = true end
    
    local self = setmetatable({
        _duration = duration,
        _remaining = duration,
        _startTime = GetGameTimer(),
        _onEnd = onEnd,
        _paused = false,
        _ended = false,
        _pauseTime = 0
    }, Timer)
    
    local function runTimer()
        while not self._ended do
            if not self._paused then
                local elapsed = GetGameTimer() - self._startTime
                self._remaining = self._duration - elapsed
                
                if self._remaining <= 0 then
                    self._remaining = 0
                    self._ended = true
                    
                    if self._onEnd then
                        self._onEnd()
                    end
                    break
                end
            end
            
            Wait(50)
        end
    end
    
    if async then
        CreateThread(runTimer)
    else
        runTimer()
    end
    
    return self
end

---Pause the timer
---@return self
function Timer:pause()
    if not self._paused and not self._ended then
        self._paused = true
        self._pauseTime = GetGameTimer()
        self._remaining = self._duration - (self._pauseTime - self._startTime)
    end
    return self
end

---Resume the timer
---@return self
function Timer:play()
    if self._paused and not self._ended then
        self._paused = false
        local pauseDuration = GetGameTimer() - self._pauseTime
        self._startTime = self._startTime + pauseDuration
    end
    return self
end

Timer.resume = Timer.play

---Force end the timer immediately
---@param triggerCallback? boolean Whether to trigger the onEnd callback (default true)
function Timer:forceEnd(triggerCallback)
    if self._ended then return end
    
    self._ended = true
    self._remaining = 0
    
    if triggerCallback ~= false and self._onEnd then
        self._onEnd()
    end
end

---Restart the timer
---@return self
function Timer:restart()
    self._startTime = GetGameTimer()
    self._remaining = self._duration
    self._paused = false
    self._ended = false
    
    CreateThread(function()
        while not self._ended do
            if not self._paused then
                local elapsed = GetGameTimer() - self._startTime
                self._remaining = self._duration - elapsed
                
                if self._remaining <= 0 then
                    self._remaining = 0
                    self._ended = true
                    
                    if self._onEnd then
                        self._onEnd()
                    end
                    break
                end
            end
            
            Wait(50)
        end
    end)
    
    return self
end

---Check if timer is paused
---@return boolean
function Timer:isPaused()
    return self._paused
end

---Check if timer has ended
---@return boolean
function Timer:hasEnded()
    return self._ended
end

---Get remaining time in milliseconds
---@return number
function Timer:getTimeLeft()
    if self._ended then return 0 end
    if self._paused then return self._remaining end
    
    local elapsed = GetGameTimer() - self._startTime
    local remaining = self._duration - elapsed
    return remaining > 0 and remaining or 0
end

---Get remaining time formatted as MM:SS
---@return string
function Timer:getTimeLeftFormatted()
    local ms = self:getTimeLeft()
    local seconds = math.floor(ms / 1000)
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    return string.format('%02d:%02d', minutes, seconds)
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('timer', timer)

-- ============================================================================
-- ATTACH TO LIB
-- ============================================================================

lib.timer = timer

return timer
