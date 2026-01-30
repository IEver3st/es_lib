--[[
    Everest Lib - Menu System (Client)
    Keyboard + mouse menu inspired by ox_lib's ergonomics.
]]

---@class EsMenuOption
---@field label string
---@field description? string
---@field icon? string
---@field iconColor? string
---@field progress? number
---@field values? string[]|{ label: string, description?: string }[]
---@field checked? boolean
---@field defaultIndex? number
---@field args? table<string, any>
---@field close? boolean

---@alias EsMenuPosition 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'

---@class EsMenu
---@field id string
---@field title string
---@field subtitle? string
---@field options EsMenuOption[]
---@field position? EsMenuPosition
---@field disableInput? boolean
---@field canClose? boolean
---@field onClose? fun(keyPressed?: 'Escape'|'Backspace')
---@field onSelected? fun(selected: number, secondary: number|boolean, args: table)
---@field onSideScroll? fun(selected: number, scrollIndex: number, args: table)
---@field onCheck? fun(selected: number, checked: boolean, args: table)

---@alias EsMenuPressCb fun(selected: number, scrollIndex: number, args: table)

local Menus = {}
local OpenMenuId = nil

-- ============================================================================
-- CONTROL LOCK (camera + combat) while menu open
-- ============================================================================

local controlsLocked = false
local controlThreadActive = false

local LookControls = { 1, 2, 3, 4 }
local CombatControls = { 24, 25, 68, 69, 70, 91, 92 }

local function startControlLock()
    if controlThreadActive then return end

    controlThreadActive = true

    CreateThread(function()
        while controlsLocked do
            for i = 1, #LookControls do
                DisableControlAction(0, LookControls[i], true)
            end

            DisablePlayerFiring(PlayerId(), true)
            for i = 1, #CombatControls do
                DisableControlAction(0, CombatControls[i], true)
            end

            Wait(0)
        end

        controlThreadActive = false
    end)
end

local function stopControlLock()
    controlsLocked = false
end

local function shallowCopyOption(option)
    return {
        label = option.label,
        description = option.description,
        icon = option.icon,
        iconColor = option.iconColor,
        progress = option.progress,
        values = option.values,
        checked = option.checked,
        defaultIndex = option.defaultIndex,
        args = option.args,
        close = option.close,
    }
end

---@param menu EsMenu
local function buildNuiMenu(menu)
    local options = {}
    for i = 1, #menu.options do
        options[i] = shallowCopyOption(menu.options[i])
    end

    return {
        id = menu.id,
        title = menu.title,
        subtitle = menu.subtitle,
        position = menu.position or 'top-left',
        disableInput = menu.disableInput or false,
        canClose = menu.canClose ~= false,
        options = options,
    }
end

---@param id string
---@return EsMenu|nil
local function getMenu(id)
    return Menus[id]
end

---@param menu EsMenu
---@param cb EsMenuPressCb
local function registerMenu(menu, cb)
    if type(menu) ~= 'table' then
        error('es_lib.registerMenu: menu must be a table')
    end

    if type(menu.id) ~= 'string' or menu.id == '' then
        error('es_lib.registerMenu: menu.id must be a string')
    end

    if type(menu.title) ~= 'string' then
        error('es_lib.registerMenu: menu.title must be a string')
    end

    if type(menu.options) ~= 'table' then
        error('es_lib.registerMenu: menu.options must be a table')
    end

    Menus[menu.id] = {
        id = menu.id,
        title = menu.title,
        subtitle = menu.subtitle,
        position = menu.position,
        disableInput = menu.disableInput,
        canClose = menu.canClose,
        options = menu.options,
        onClose = menu.onClose,
        onSelected = menu.onSelected,
        onSideScroll = menu.onSideScroll,
        onCheck = menu.onCheck,
        cb = cb,
    }

    return true
end

---@param id string
local function showMenu(id)
    local menu = getMenu(id)
    if not menu then
        print(('^1[es_lib]^7 showMenu failed: unknown id %s'):format(tostring(id)))
        return false
    end

    OpenMenuId = id

    local payload = buildNuiMenu(menu)

    SendNUIMessage({
        action = 'menuOpen',
        data = payload
    })

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)

    controlsLocked = true
    startControlLock()

    return true
end

---@param runOnClose? boolean
local function hideMenu(runOnClose)
    if not OpenMenuId then
        return false
    end

    local menu = getMenu(OpenMenuId)

    SendNUIMessage({ action = 'menuClose' })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    stopControlLock()

    local prevId = OpenMenuId
    OpenMenuId = nil

    if runOnClose and menu and menu.onClose then
        menu.onClose()
    end

    return prevId
end

---@return string|nil
local function getOpenMenu()
    return OpenMenuId
end

---@param id string
---@param options table
---@param index? number
local function setMenuOptions(id, options, index)
    local menu = getMenu(id)
    if not menu then
        return false
    end

    if index then
        if type(index) ~= 'number' or index < 1 then
            return false
        end

        menu.options[index] = options

        if OpenMenuId == id then
            SendNUIMessage({
                action = 'menuSetOption',
                data = { id = id, index = index, option = shallowCopyOption(options) }
            })
        end

        return true
    end

    menu.options = options

    if OpenMenuId == id then
        local packed = {}
        for i = 1, #options do
            packed[i] = shallowCopyOption(options[i])
        end

        SendNUIMessage({
            action = 'menuSetOptions',
            data = { id = id, options = packed }
        })
    end

    return true
end

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('es_menu_close', function(data, cb)
    local id = data and data.id
    local keyPressed = data and data.keyPressed

    if OpenMenuId and id and OpenMenuId ~= id then
        cb({ ok = true })
        return
    end

    local menu = OpenMenuId and getMenu(OpenMenuId)

    OpenMenuId = nil
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    stopControlLock()

    if menu and menu.onClose then
        menu.onClose(keyPressed)
    end

    cb({ ok = true })
end)

RegisterNUICallback('es_menu_selected', function(data, cb)
    local id = data and data.id
    if not id or OpenMenuId ~= id then
        cb({ ok = true })
        return
    end

    local menu = getMenu(id)
    if menu and menu.onSelected then
        menu.onSelected(data.selected, data.secondary, data.args or {})
    end

    cb({ ok = true })
end)

RegisterNUICallback('es_menu_sideScroll', function(data, cb)
    local id = data and data.id
    if not id or OpenMenuId ~= id then
        cb({ ok = true })
        return
    end

    local menu = getMenu(id)
    if menu and menu.onSideScroll then
        menu.onSideScroll(data.selected, data.scrollIndex, data.args or {})
    end

    cb({ ok = true })
end)

RegisterNUICallback('es_menu_check', function(data, cb)
    local id = data and data.id
    if not id or OpenMenuId ~= id then
        cb({ ok = true })
        return
    end

    local menu = getMenu(id)
    if menu and menu.onCheck then
        menu.onCheck(data.selected, data.checked, data.args or {})
    end

    cb({ ok = true })
end)

RegisterNUICallback('es_menu_submit', function(data, cb)
    local id = data and data.id
    if not id or OpenMenuId ~= id then
        cb({ ok = true })
        return
    end

    local menu = getMenu(id)
    if not menu then
        cb({ ok = true })
        return
    end

    local selected = data.selected
    local scrollIndex = data.scrollIndex
    local args = data.args or {}

    if menu.cb then
        menu.cb(selected, scrollIndex, args)
    end

    local option = menu.options[selected]
    local shouldClose = option and option.close ~= false

    if shouldClose and OpenMenuId == id then
        OpenMenuId = nil
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        stopControlLock()
        SendNUIMessage({ action = 'menuClose' })
    else
        shouldClose = false
    end

    cb({ ok = true, close = shouldClose })
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('registerMenu', registerMenu)
exports('showMenu', showMenu)
exports('hideMenu', hideMenu)
exports('getOpenMenu', getOpenMenu)
exports('setMenuOptions', setMenuOptions)

-- ============================================================================
-- ATTACH TO LIB
-- ============================================================================

lib.registerMenu = registerMenu
lib.showMenu = showMenu
lib.hideMenu = hideMenu
lib.getOpenMenu = getOpenMenu
lib.setMenuOptions = setMenuOptions

return {
    registerMenu = registerMenu,
    showMenu = showMenu,
    hideMenu = hideMenu,
    getOpenMenu = getOpenMenu,
    setMenuOptions = setMenuOptions
}
