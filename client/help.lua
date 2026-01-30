local lib = {}
local helpState = {
    open = false
}

function lib.showHelp(items)
    if not items or #items == 0 then return false end

    helpState.open = true
    SendNUIMessage({
        action = 'helpShow',
        data = { items = items }
    })
    return true
end

function lib.hideHelp()
    if not helpState.open then return false end

    helpState.open = false
    SendNUIMessage({
        action = 'helpHide'
    })
    return true
end

exports('showHelp', lib.showHelp)
exports('hideHelp', lib.hideHelp)

return lib
