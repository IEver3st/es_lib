local helpState = {
    open = false
}

local function showHelp(items)
    if not items or #items == 0 then return false end

    helpState.open = true
    SendNUIMessage({
        action = 'helpShow',
        data = { items = items }
    })
    return true
end

local function hideHelp()
    if not helpState.open then return false end

    helpState.open = false
    SendNUIMessage({
        action = 'helpHide'
    })
    return true
end

exports('showHelp', showHelp)
exports('hideHelp', hideHelp)

lib.showHelp = showHelp
lib.hideHelp = hideHelp

return {
    showHelp = showHelp,
    hideHelp = hideHelp
}
