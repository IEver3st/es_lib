local DisableControlAction = DisableControlAction
local DisablePlayerFiring = DisablePlayerFiring
local DisableAllControlActions = DisableAllControlActions
local PlayerPedId = PlayerPedId
local PlayerId = PlayerId
local Wait = Wait

local CONTROL_GROUPS = {
    movement = {30, 31, 32, 33, 34, 35, 36, 21, 22, 44, 45, 269, 270},
    carMovement = {59, 60, 71, 72, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90},
    combat = {24, 25, 37, 47, 58, 140, 141, 142, 143, 257, 263, 264, 265},
    mouse = {1, 2, 106}
}

local CONTROL_MAP = {
    INPUT_LOOK_LR = 1,
    INPUT_LOOK_UD = 2,
    INPUT_ATTACK = 24,
    INPUT_AIM = 25,
    INPUT_MOVE_LR = 30,
    INPUT_MOVE_UD = 31,
    INPUT_DUCK = 36,
    INPUT_VEH_MOVE_LR = 59,
    INPUT_VEH_MOVE_UD = 60,
    INPUT_VEH_ACCELERATE = 71,
    INPUT_VEH_BRAKE = 72,
    INPUT_VEH_EXIT = 75,
    INPUT_VEH_HANDBRAKE = 76,
    INPUT_JUMP = 22,
    INPUT_SPRINT = 21,
    INPUT_ENTER = 23,
    INPUT_RELOAD = 45,
    INPUT_MELEE_ATTACK = 140,
    INPUT_VEH_ATTACK = 69,
    INPUT_VEH_ATTACK2 = 68,
    INPUT_COVER = 44
}

local DisableControls = {}
DisableControls.__index = DisableControls

local function disableControls(options)
    options = options or {}
    
    local self = setmetatable({
        _active = true,
        _controls = {},
        _disableMovement = options.disableMovement or options.move or false,
        _disableCarMovement = options.disableCarMovement or options.car or false,
        _disableCombat = options.disableCombat or options.combat or false,
        _disableMouse = options.disableMouse or options.mouse or false,
        _disableAll = options.disableAll or false
    }, DisableControls)
    
    CreateThread(function()
        while self._active do
            local playerId = PlayerId()
            
            if self._disableAll then
                DisableAllControlActions(0)
            else
                if self._disableMovement then
                    for _, control in ipairs(CONTROL_GROUPS.movement) do
                        DisableControlAction(0, control, true)
                    end
                end
                
                if self._disableCarMovement then
                    for _, control in ipairs(CONTROL_GROUPS.carMovement) do
                        DisableControlAction(0, control, true)
                    end
                end
                
                if self._disableCombat then
                    for _, control in ipairs(CONTROL_GROUPS.combat) do
                        DisableControlAction(0, control, true)
                    end
                    DisablePlayerFiring(playerId, true)
                end
                
                if self._disableMouse then
                    for _, control in ipairs(CONTROL_GROUPS.mouse) do
                        DisableControlAction(0, control, true)
                    end
                end
                
                for control, _ in pairs(self._controls) do
                    DisableControlAction(0, control, true)
                end
            end
            
            Wait(0)
        end
    end)
    
    return self
end

function DisableControls:Add(control)
    if type(control) == 'string' then
        control = CONTROL_MAP[control] or control
    end
    
    if type(control) == 'number' then
        self._controls[control] = true
    end
    
    return self
end

function DisableControls:Remove(control)
    if type(control) == 'string' then
        control = CONTROL_MAP[control] or control
    end
    
    if type(control) == 'number' then
        self._controls[control] = nil
    end
    
    return self
end

function DisableControls:Clear()
    self._controls = {}
    return self
end

function DisableControls:Destroy()
    self._active = false
    self._controls = {}
end

DisableControls.destroy = DisableControls.Destroy

exports('disableControls', disableControls)

lib.disableControls = disableControls

return disableControls
