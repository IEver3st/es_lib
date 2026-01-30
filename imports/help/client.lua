--[[
    Everest Lib - Help Module (Client)
    Displays a persistent help bar at the bottom of the screen with keybind hints.
]]

local helpState = {
    open = false
}

---@class EsHelpItem
---@field label string
---@field value string

---@param items EsHelpItem[]
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

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('showHelp', showHelp)
exports('hideHelp', hideHelp)

-- ============================================================================
-- ATTACH TO LIB
-- ============================================================================

lib.showHelp = showHelp
lib.hideHelp = hideHelp

return {
    showHelp = showHelp,
    hideHelp = hideHelp
}
