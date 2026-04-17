local GetGameTimer = GetGameTimer
local Wait = Wait

local Timer = {}
Timer.__index = Timer

local function runTimer(self, runId)
    while not self._ended and self._runId == runId do
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

local function timer(duration, onEnd, async)
    if async == nil then async = true end
    
    local self = setmetatable({
        _duration = duration,
        _remaining = duration,
        _startTime = GetGameTimer(),
        _onEnd = onEnd,
        _paused = false,
        _ended = false,
        _pauseTime = 0,
        _runId = 0
    }, Timer)

    self._runId = self._runId + 1
    local runId = self._runId

    if async then
        CreateThread(function()
            runTimer(self, runId)
        end)
    else
        runTimer(self, runId)
    end
    
    return self
end

function Timer:pause()
    if not self._paused and not self._ended then
        self._paused = true
        self._pauseTime = GetGameTimer()
        self._remaining = self._duration - (self._pauseTime - self._startTime)
    end
    return self
end

function Timer:play()
    if self._paused and not self._ended then
        self._paused = false
        local pauseDuration = GetGameTimer() - self._pauseTime
        self._startTime = self._startTime + pauseDuration
    end
    return self
end

Timer.resume = Timer.play

function Timer:forceEnd(triggerCallback)
    if self._ended then return end
    
    self._ended = true
    self._remaining = 0
    
    if triggerCallback ~= false and self._onEnd then
        self._onEnd()
    end
end

function Timer:restart()
    self._startTime = GetGameTimer()
    self._remaining = self._duration
    self._paused = false
    self._ended = false
    self._runId = self._runId + 1

    local runId = self._runId
    CreateThread(function()
        runTimer(self, runId)
    end)
    
    return self
end

function Timer:isPaused()
    return self._paused
end

function Timer:hasEnded()
    return self._ended
end

function Timer:getTimeLeft()
    if self._ended then return 0 end
    if self._paused then return self._remaining end
    
    local elapsed = GetGameTimer() - self._startTime
    local remaining = self._duration - elapsed
    return remaining > 0 and remaining or 0
end

function Timer:getTimeLeftFormatted()
    local ms = self:getTimeLeft()
    local seconds = math.floor(ms / 1000)
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    return string.format('%02d:%02d', minutes, seconds)
end

exports('timer', timer)

lib.timer = timer

return timer
