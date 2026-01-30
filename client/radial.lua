lib = lib or {}

local SetNuiFocus = SetNuiFocus
local SendNUIMessage = SendNUIMessage

local registeredMenus = {}
local globalItems = {}
local currentMenu = nil
local menuStack = {}
local isOpen = false

function lib.registerRadial(data)
    if not data.id then
        error('lib.registerRadial requires an id')
    end
    
    registeredMenus[data.id] = {
        id = data.id,
        items = data.items or {},
        onOpen = data.onOpen,
        onClose = data.onClose
    }
end

function lib.showRadial(id, keepStack)
    local menu = registeredMenus[id]
    if not menu then
        return false
    end
    
    if not keepStack then
        menuStack = {}
    end
    
    if currentMenu and currentMenu ~= id then
        table.insert(menuStack, currentMenu)
    end
    
    currentMenu = id
    isOpen = true
    
    local allItems = {}
    
    for _, item in ipairs(menu.items) do
        table.insert(allItems, item)
    end
    
    for _, item in ipairs(globalItems) do
        local visible = true
        if item.shouldShow then
            visible = item.shouldShow()
        end
        if visible then
            table.insert(allItems, item)
        end
    end
    
    SendNUIMessage({
        action = 'radialShow',
        data = {
            menuId = id,
            items = allItems,
            canGoBack = #menuStack > 0
        }
    })
    
    SetNuiFocus(true, true)
    
    if menu.onOpen then
        menu.onOpen()
    end
    
    return true
end

function lib.hideRadial(skipCallback)
    if not isOpen then return end
    
    local menu = currentMenu and registeredMenus[currentMenu]
    
    SendNUIMessage({
        action = 'radialHide'
    })
    
    SetNuiFocus(false, false)
    
    if not skipCallback and menu and menu.onClose then
        menu.onClose()
    end
    
    isOpen = false
    currentMenu = nil
    menuStack = {}
end

function lib.radialBack()
    if #menuStack == 0 then
        lib.hideRadial()
        return
    end
    
    local previousMenu = table.remove(menuStack)
    currentMenu = nil
    lib.showRadial(previousMenu, true)
end

function lib.addRadialItem(id, item)
    local menu = registeredMenus[id]
    if not menu then
        registeredMenus[id] = { id = id, items = {} }
        menu = registeredMenus[id]
    end
    
    for i, existing in ipairs(menu.items) do
        if existing.id == item.id then
            menu.items[i] = item
            return
        end
    end
    
    table.insert(menu.items, item)
end

function lib.removeRadialItem(menuId, itemId)
    local menu = registeredMenus[menuId]
    if not menu then return end
    
    for i, item in ipairs(menu.items) do
        if item.id == itemId then
            table.remove(menu.items, i)
            return true
        end
    end
    
    return false
end

function lib.clearRadial(id)
    local menu = registeredMenus[id]
    if menu then
        menu.items = {}
    end
end

function lib.addGlobalRadialItem(item)
    if not item.id then
        error('Global radial item requires an id')
    end
    
    for i, existing in ipairs(globalItems) do
        if existing.id == item.id then
            globalItems[i] = item
            return
        end
    end
    
    table.insert(globalItems, item)
end

function lib.removeGlobalRadialItem(id)
    for i, item in ipairs(globalItems) do
        if item.id == id then
            table.remove(globalItems, i)
            return true
        end
    end
    return false
end

function lib.getGlobalRadialItems()
    return globalItems
end

function lib.isRadialOpen()
    return isOpen
end

function lib.getCurrentRadial()
    return currentMenu
end

function lib.refreshRadial()
    if isOpen and currentMenu then
        lib.showRadial(currentMenu, true)
    end
end

RegisterNUICallback('radialClick', function(data, cb)
    cb('ok')
    
    local index = (data.index or 0) + 1
    local menu = currentMenu and registeredMenus[currentMenu]
    
    local allItems = {}
    
    if menu then
        for _, item in ipairs(menu.items) do
            table.insert(allItems, item)
        end
    end
    
    for _, item in ipairs(globalItems) do
        local visible = true
        if item.shouldShow then
            visible = item.shouldShow()
        end
        if visible then
            table.insert(allItems, item)
        end
    end
    
    local selectedItem = allItems[index]
    
    if not selectedItem then return end
    
    if selectedItem.menu then
        lib.showRadial(selectedItem.menu)
        return
    end
    
    if not selectedItem.keepOpen then
        lib.hideRadial(true)
    end
    
    if selectedItem.onSelect then
        selectedItem.onSelect(selectedItem)
    end
end)

RegisterNUICallback('radialClose', function(data, cb)
    cb('ok')
    lib.hideRadial()
end)

RegisterNUICallback('radialBack', function(data, cb)
    cb('ok')
    lib.radialBack()
end)

exports('registerRadial', lib.registerRadial)
exports('showRadial', lib.showRadial)
exports('hideRadial', lib.hideRadial)
exports('radialBack', lib.radialBack)
exports('addRadialItem', lib.addRadialItem)
exports('removeRadialItem', lib.removeRadialItem)
exports('clearRadial', lib.clearRadial)
exports('addGlobalRadialItem', lib.addGlobalRadialItem)
exports('removeGlobalRadialItem', lib.removeGlobalRadialItem)
exports('getGlobalRadialItems', lib.getGlobalRadialItems)
exports('isRadialOpen', lib.isRadialOpen)
exports('getCurrentRadial', lib.getCurrentRadial)
exports('refreshRadial', lib.refreshRadial)

return lib
