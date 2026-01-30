--[[
    Everest Lib - Radial Menu Module
    High-performance radial menu based on ox_lib's architecture
    with es_lib's HUD design language.
]]

-- ============================================================================
-- CACHED NATIVES
-- ============================================================================

local SetNuiFocus = SetNuiFocus
local SetCursorLocation = SetCursorLocation
local SendNUIMessage = SendNUIMessage
local DisablePlayerFiring = DisablePlayerFiring
local DisableControlAction = DisableControlAction
local Wait = Wait
local CreateThread = CreateThread
local PlayerId = PlayerId
local IsPauseMenuActive = IsPauseMenuActive
local IsNuiFocused = IsNuiFocused

-- ============================================================================
-- STATE
-- ============================================================================

---@class RadialItem
---@field id string Unique identifier for the item
---@field label string Display label
---@field icon? string Icon (emoji, FontAwesome class, or URL)
---@field iconColor? string Icon color override
---@field menu? string ID of submenu to navigate to
---@field onSelect? fun(currentMenu: string?, itemIndex: number) Callback when selected
---@field keepOpen? boolean Keep menu open after selection

---@class RadialMenu
---@field id string Menu identifier
---@field items RadialItem[] Menu items

local isOpen = false
local isDisabled = false
local menus = {}           -- Registered submenus { [id] = { items = {...} } }
local menuItems = {}       -- Global menu items (shown on root)
local menuHistory = {}     -- Navigation breadcrumb for submenus
local currentRadial = nil  -- Current submenu ID (nil = global/root menu)

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

---Sanitize item for NUI (strip functions, keep only serializable data)
---@param item RadialItem
---@return table
local function sanitizeItem(item)
    return {
        id = item.id,
        label = item.label,
        icon = item.icon,
        iconColor = item.iconColor,
        menu = item.menu,
        keepOpen = item.keepOpen,
    }
end

---Build the items array for NUI based on current menu state
---@return table[]
local function buildNuiItems()
    local items
    
    if currentRadial then
        local menu = menus[currentRadial]
        items = menu and menu.items or {}
    else
        items = menuItems
    end
    
    local sanitized = {}
    for i = 1, #items do
        sanitized[i] = sanitizeItem(items[i])
    end
    
    return sanitized
end

---Get the raw item by index (1-based) from current menu
---@param index number
---@return RadialItem?
local function getItemByIndex(index)
    local items
    
    if currentRadial then
        local menu = menus[currentRadial]
        items = menu and menu.items or {}
    else
        items = menuItems
    end
    
    return items[index]
end

---Send radial state to NUI
local function refreshRadial()
    if not isOpen then return end
    
    SendNUIMessage({
        action = 'radialRefresh',
        data = {
            items = buildNuiItems(),
            menuId = currentRadial,
            canGoBack = #menuHistory > 0
        }
    })
end

-- ============================================================================
-- CONTROL THREAD (runs only while menu is open)
-- ============================================================================

local controlThread = nil

local function startControlThread()
    if controlThread then return end
    
    controlThread = CreateThread(function()
        while isOpen do
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 1, true)   -- Look Left/Right
            DisableControlAction(0, 2, true)   -- Look Up/Down  
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(2, 199, true) -- Pause Menu
            DisableControlAction(2, 200, true) -- Pause Menu Alt
            Wait(0)
        end
        controlThread = nil
    end)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

---Add item(s) to the global radial menu
---@param items RadialItem|RadialItem[]
local function addRadialItem(items)
    if items.id then
        -- Single item
        items = { items }
    end
    
    for i = 1, #items do
        local item = items[i]
        if not item.id then
            error('lib.addRadialItem: item requires an id')
        end
        
        -- Check for existing item with same id, update it
        local found = false
        for j = 1, #menuItems do
            if menuItems[j].id == item.id then
                menuItems[j] = item
                found = true
                break
            end
        end
        
        if not found then
            menuItems[#menuItems + 1] = item
        end
    end
    
    refreshRadial()
end

---Remove an item from the global radial menu by ID
---@param id string
---@return boolean
local function removeRadialItem(id)
    for i = #menuItems, 1, -1 do
        if menuItems[i].id == id then
            table.remove(menuItems, i)
            refreshRadial()
            return true
        end
    end
    return false
end

---Clear all items from the global radial menu
local function clearRadialItems()
    table.wipe(menuItems)
    refreshRadial()
end

---Register a submenu
---@param data RadialMenu
local function registerRadial(data)
    if not data.id then
        error('lib.registerRadial: menu requires an id')
    end
    
    menus[data.id] = {
        id = data.id,
        items = data.items or {}
    }
end

---Show the radial menu (opens to global menu or specified submenu)
---@param menuId? string Optional submenu ID to open directly
---@return boolean
local function showRadial(menuId)
    if isDisabled then return false end
    if isOpen then return false end
    if IsPauseMenuActive() then return false end
    if IsNuiFocused() then return false end
    
    local items
    
    if menuId then
        local menu = menus[menuId]
        if not menu then
            print(('^1[es_lib]^7 showRadial: unknown menu id "%s"'):format(menuId))
            return false
        end
        currentRadial = menuId
        items = menu.items
    else
        currentRadial = nil
        items = menuItems
    end
    
    if #items == 0 then
        return false
    end
    
    isOpen = true
    menuHistory = {}
    
    SendNUIMessage({
        action = 'radialShow',
        data = {
            items = buildNuiItems(),
            menuId = currentRadial,
            canGoBack = false
        }
    })
    
    SetCursorLocation(0.5, 0.5)
    SetNuiFocus(true, true)
    startControlThread()
    
    return true
end

---Hide the radial menu
---@param skipTransition? boolean Skip the close animation
local function hideRadial(skipTransition)
    if not isOpen then return end
    
    isOpen = false
    currentRadial = nil
    menuHistory = {}
    
    SendNUIMessage({
        action = 'radialHide',
        data = { instant = skipTransition }
    })
    
    SetNuiFocus(false, false)
end

---Navigate to a submenu
---@param menuId string
local function navigateToMenu(menuId)
    local menu = menus[menuId]
    if not menu then return end
    
    -- Push current menu to history
    menuHistory[#menuHistory + 1] = currentRadial
    currentRadial = menuId
    
    -- Transition animation
    SendNUIMessage({ action = 'radialTransitionOut' })
    Wait(100)
    
    if isOpen then
        SendNUIMessage({
            action = 'radialTransitionIn',
            data = {
                items = buildNuiItems(),
                menuId = currentRadial,
                canGoBack = #menuHistory > 0
            }
        })
    end
end

---Go back to the previous menu
local function radialBack()
    if #menuHistory == 0 then
        hideRadial()
        return
    end
    
    currentRadial = table.remove(menuHistory)
    
    SendNUIMessage({ action = 'radialTransitionOut' })
    Wait(100)
    
    if isOpen then
        SendNUIMessage({
            action = 'radialTransitionIn',
            data = {
                items = buildNuiItems(),
                menuId = currentRadial,
                canGoBack = #menuHistory > 0
            }
        })
    end
end

---Disable or enable the radial menu
---@param state boolean
local function disableRadial(state)
    isDisabled = state
    if state and isOpen then
        hideRadial(true)
    end
end

---Check if radial is currently open
---@return boolean
local function isRadialOpen()
    return isOpen
end

---Check if radial is disabled
---@return boolean
local function isRadialDisabled()
    return isDisabled
end

---Get the current submenu ID (nil if on global menu)
---@return string?
local function getCurrentRadialId()
    return currentRadial
end

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('radialClick', function(data, cb)
    cb('ok')
    
    local index = (data.index or 0) + 1  -- Convert 0-based to 1-based
    local item = getItemByIndex(index)
    
    if not item then return end
    
    -- Navigate to submenu
    if item.menu then
        navigateToMenu(item.menu)
        return
    end
    
    -- Close menu unless keepOpen
    if not item.keepOpen then
        hideRadial()
    end
    
    -- Execute callback
    if item.onSelect then
        item.onSelect(currentRadial, index)
    end
end)

RegisterNUICallback('radialBack', function(_, cb)
    cb('ok')
    radialBack()
end)

RegisterNUICallback('radialClose', function(_, cb)
    cb('ok')
    hideRadial()
end)

-- ============================================================================
-- RESOURCE CLEANUP
-- ============================================================================

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isOpen then
            hideRadial(true)
        end
    end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('addRadialItem', addRadialItem)
exports('removeRadialItem', removeRadialItem)
exports('clearRadialItems', clearRadialItems)
exports('registerRadial', registerRadial)
exports('showRadial', showRadial)
exports('hideRadial', hideRadial)
exports('disableRadial', disableRadial)
exports('isRadialOpen', isRadialOpen)
exports('isRadialDisabled', isRadialDisabled)
exports('getCurrentRadialId', getCurrentRadialId)

-- ============================================================================
-- ATTACH TO LIB
-- ============================================================================

lib.addRadialItem = addRadialItem
lib.removeRadialItem = removeRadialItem
lib.clearRadialItems = clearRadialItems
lib.registerRadial = registerRadial
lib.showRadial = showRadial
lib.hideRadial = hideRadial
lib.disableRadial = disableRadial
lib.isRadialOpen = isRadialOpen
lib.isRadialDisabled = isRadialDisabled
lib.getCurrentRadialId = getCurrentRadialId

return {
    addRadialItem = addRadialItem,
    removeRadialItem = removeRadialItem,
    clearRadialItems = clearRadialItems,
    registerRadial = registerRadial,
    showRadial = showRadial,
    hideRadial = hideRadial,
    disableRadial = disableRadial,
    isRadialOpen = isRadialOpen,
    isRadialDisabled = isRadialDisabled,
    getCurrentRadialId = getCurrentRadialId,
}
