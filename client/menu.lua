local Menus = {}
local OpenMenuId = nil

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

local function getMenu(id)
    return Menus[id]
end

function lib.registerMenu(menu, cb)
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

function lib.showMenu(id)
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

function lib.hideMenu(runOnClose)
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

function lib.getOpenMenu()
    return OpenMenuId
end

function lib.setMenuOptions(id, options, index)
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

CreateThread(function()
    print('^2[es_lib]^7 menu module loaded')
end)

exports('registerMenu', lib.registerMenu)
exports('showMenu', lib.showMenu)
exports('hideMenu', lib.hideMenu)
exports('getOpenMenu', lib.getOpenMenu)
exports('setMenuOptions', lib.setMenuOptions)

return lib
