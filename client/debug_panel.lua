lib = lib or {}

local panelState = {
    open = false,
    id = nil,
    lastPayload = nil,
}

local function normalizePayload(payload)
    if type(payload) ~= 'table' then payload = {} end

    local out = {}
    out.id = payload.id
    out.title = payload.title
    out.subtitle = payload.subtitle
    out.position = payload.position or 'top-right'
    out.accentColor = payload.accentColor
    out.lines = payload.lines
    out.data = payload.data

    return out
end

function lib.showDebugPanel(payload)
    local data = normalizePayload(payload)

    panelState.open = true
    panelState.id = data.id or panelState.id
    panelState.lastPayload = data

    SendNUIMessage({
        action = 'debugPanelShow',
        data = data
    })

    return true
end

function lib.updateDebugPanel(payload)
    if not panelState.open then
        return false
    end

    local data = normalizePayload(payload)
    panelState.lastPayload = data

    SendNUIMessage({
        action = 'debugPanelUpdate',
        data = data
    })

    return true
end

function lib.hideDebugPanel()
    if not panelState.open then
        return false
    end

    panelState.open = false
    panelState.id = nil
    panelState.lastPayload = nil

    SendNUIMessage({
        action = 'debugPanelHide'
    })

    return true
end

function lib.isDebugPanelOpen()
    return panelState.open
end

exports('showDebugPanel', lib.showDebugPanel)
exports('updateDebugPanel', lib.updateDebugPanel)
exports('hideDebugPanel', lib.hideDebugPanel)
exports('isDebugPanelOpen', lib.isDebugPanelOpen)

return lib
