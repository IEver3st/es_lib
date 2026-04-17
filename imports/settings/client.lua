local GetResourceKvpString = GetResourceKvpString
local SetResourceKvp = SetResourceKvp
local SendNUIMessage = SendNUIMessage
local SetNuiFocus = SetNuiFocus
local GetNumResources = GetNumResources
local GetResourceByFindIndex = GetResourceByFindIndex
local GetResourceState = GetResourceState

local KVP_PREFIX = 'eslib:settings:'
local isOpen = false

-- Registry: scriptId -> { label, settings = {}, sections = {} }
local registeredScripts = {}
-- Flat key->value store for all settings across all scripts
local settingsValues = {}
-- Flat key->default store
local settingsDefaults = {}
-- Callbacks: key -> list of functions to call on change
local changeCallbacks = {}

-- ============================================================================
-- KVP PERSISTENCE
-- ============================================================================

local function loadValue(key, defaultValue)
    local raw = GetResourceKvpString(KVP_PREFIX .. key)
    if raw == nil then return defaultValue end

    if type(defaultValue) == 'boolean' then
        return raw == 'true'
    elseif type(defaultValue) == 'number' then
        return tonumber(raw) or defaultValue
    else
        return raw
    end
end

local function saveValue(key, value)
    if type(value) == 'boolean' then
        SetResourceKvp(KVP_PREFIX .. key, value and 'true' or 'false')
    elseif type(value) == 'number' then
        SetResourceKvp(KVP_PREFIX .. key, tostring(value))
    else
        SetResourceKvp(KVP_PREFIX .. key, tostring(value))
    end
end

-- ============================================================================
-- SCRIPT REGISTRATION
-- ============================================================================

local function registerScript(scriptId, definition)
    if not scriptId or not definition then return end

    registeredScripts[scriptId] = {
        label = definition.label or scriptId,
        settings = definition.settings or {},
        sections = definition.sections or nil,
    }

    for _, field in ipairs(definition.settings or {}) do
        if field.key and field.default ~= nil then
            settingsDefaults[field.key] = field.default
            if settingsValues[field.key] == nil then
                settingsValues[field.key] = loadValue(field.key, field.default)
            end
        end
    end
end

-- ============================================================================
-- AUTO-DETECT ES_ SCRIPTS
-- ============================================================================

local function autoDetectScripts()
    local count = GetNumResources()
    for i = 0, count - 1 do
        local name = GetResourceByFindIndex(i)
        if name and name:sub(1, 3) == 'es_' and name ~= 'es_lib' then
            local state = GetResourceState(name)
            if state == 'started' then
                local ok, result = pcall(function()
                    return exports[name]:getSettingsDefinition()
                end)
                if ok and result and type(result) == 'table' then
                    registerScript(name, result)
                end
            end
        end
    end
end

-- ============================================================================
-- BUILT-IN ES_LIB SETTINGS
-- ============================================================================

local function registerBuiltinSettings()
    registerScript('es_lib', {
        label = 'ES Lib',
        settings = {
            {
                key = 'notifySound',
                type = 'toggle',
                label = 'Notification Sound',
                description = 'Play audio on notifications',
                default = true,
            },
            {
                key = 'notifyPosition',
                type = 'select',
                label = 'Notification Position',
                description = 'Where notifications appear on screen',
                default = 'top-right',
                options = {
                    { value = 'top-right', label = 'Top Right' },
                    { value = 'top-left', label = 'Top Left' },
                    { value = 'top', label = 'Top Center' },
                    { value = 'bottom-right', label = 'Bottom Right' },
                    { value = 'bottom-left', label = 'Bottom Left' },
                    { value = 'bottom', label = 'Bottom Center' },
                },
            },
        },
        sections = {
            { label = 'Notifications', keys = { 'notifySound', 'notifyPosition' } },
        },
    })
end

-- ============================================================================
-- OPEN / CLOSE SETTINGS PANEL
-- ============================================================================

local function buildNuiPayload()
    local scripts = {}
    for scriptId, def in pairs(registeredScripts) do
        scripts[scriptId] = {
            label = def.label,
            settings = def.settings,
            sections = def.sections,
        }
    end
    return scripts, settingsValues
end

local function openSettingsMenu()
    if isOpen then return end
    isOpen = true

    local scripts, values = buildNuiPayload()
    SendNUIMessage({
        action = 'settingsOpen',
        data = {
            scripts = scripts,
            values = values,
        }
    })
    SetNuiFocus(true, true)
end

local function closeSettingsMenu()
    if not isOpen then return end
    isOpen = false
    SendNUIMessage({ action = 'settingsClose' })
    SetNuiFocus(false, false)
end

-- ============================================================================
-- APPLY SETTINGS
-- ============================================================================

local function applySettings(newValues)
    if not newValues or type(newValues) ~= 'table' then return end

    local changed = {}
    for key, value in pairs(newValues) do
        if settingsDefaults[key] ~= nil then
            local old = settingsValues[key]
            settingsValues[key] = value
            saveValue(key, value)
            if old ~= value then
                changed[key] = value
            end
        end
    end

    -- Notify all scripts about their changed settings
    for key, value in pairs(changed) do
        TriggerEvent('es_lib:settingChanged', key, value)
        if changeCallbacks[key] then
            for _, cb in ipairs(changeCallbacks[key]) do
                pcall(cb, value, key)
            end
        end
    end
end

local function setSetting(key, value)
    if settingsDefaults[key] == nil then return end

    local old = settingsValues[key]
    settingsValues[key] = value
    saveValue(key, value)

    if old ~= value then
        TriggerEvent('es_lib:settingChanged', key, value)
        if changeCallbacks[key] then
            for _, cb in ipairs(changeCallbacks[key]) do
                pcall(cb, value, key)
            end
        end
    end
end

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('eslib:settingsSave', function(data, cb)
    applySettings(data)
    closeSettingsMenu()
    lib.notify({
        type = 'success',
        title = 'Settings',
        description = 'Settings saved successfully',
        duration = 2000
    })
    cb('ok')
end)

RegisterNUICallback('eslib:settingsClose', function(_, cb)
    closeSettingsMenu()
    cb('ok')
end)

-- Relay action buttons from the settings UI to scripts
RegisterNUICallback('eslib:settingsAction', function(data, cb)
    local scriptId = data and data.scriptId
    local action = data and data.action
    if scriptId and action then
        TriggerEvent('es_lib:settingsAction', scriptId, action)
    end
    cb('ok')
end)

-- ============================================================================
-- PUBLIC API
-- ============================================================================

local function getSetting(key)
    return settingsValues[key]
end

local function getAllSettings()
    return settingsValues
end

local function onSettingChange(key, callback)
    if not changeCallbacks[key] then
        changeCallbacks[key] = {}
    end
    table.insert(changeCallbacks[key], callback)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

registerBuiltinSettings()

CreateThread(function()
    Wait(2000)
    autoDetectScripts()
end)

RegisterCommand('essettings', function()
    openSettingsMenu()
end, false)

RegisterKeyMapping('essettings', 'Open ES Settings', 'keyboard', 'HOME')

-- ============================================================================
-- EXPORTS
-- ============================================================================

lib.getSetting = getSetting
lib.getAllSettings = getAllSettings
lib.setSetting = setSetting
lib.openSettingsMenu = openSettingsMenu
lib.closeSettingsMenu = closeSettingsMenu
lib.registerSettingsScript = registerScript
lib.onSettingChange = onSettingChange

exports('getSetting', getSetting)
exports('getAllSettings', getAllSettings)
exports('setSetting', setSetting)
exports('openSettingsMenu', openSettingsMenu)
exports('closeSettingsMenu', closeSettingsMenu)
exports('registerSettingsScript', registerScript)
exports('onSettingChange', onSettingChange)

return {
    getSetting = getSetting,
    getAllSettings = getAllSettings,
    setSetting = setSetting,
    openSettingsMenu = openSettingsMenu,
    closeSettingsMenu = closeSettingsMenu,
    registerSettingsScript = registerScript,
    onSettingChange = onSettingChange,
}
