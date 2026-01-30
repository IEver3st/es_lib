local GetResourceKvpString = GetResourceKvpString
local SetResourceKvp = SetResourceKvp

local SETTINGS_PREFIX = 'eslib:'

local defaults = {
    notifySound = true,
    notifyPosition = 'top-right'
}

local settings = {}

local function loadSettings()
    for key, defaultValue in pairs(defaults) do
        local stored = GetResourceKvpString(SETTINGS_PREFIX .. key)
        if stored then
            if type(defaultValue) == 'boolean' then
                settings[key] = stored == 'true'
            else
                settings[key] = stored
            end
        else
            settings[key] = defaultValue
        end
    end
end

local function saveSetting(key, value)
    if type(value) == 'boolean' then
        SetResourceKvp(SETTINGS_PREFIX .. key, value and 'true' or 'false')
    else
        SetResourceKvp(SETTINGS_PREFIX .. key, tostring(value))
    end
    settings[key] = value
end

local function getSetting(key)
    return settings[key]
end

local function getAllSettings()
    return settings
end

local function openSettingsMenu()
    local result = lib.contextMenu({
        title = 'Settings',
        fields = {
            {
                type = 'checkbox',
                name = 'notifySound',
                label = 'Notification audio'
            },
            {
                type = 'select',
                name = 'notifyPosition',
                label = 'Notification position',
                required = true,
                icon = '💬',
                options = {
                    { value = 'top-right', label = 'Top-right' },
                    { value = 'top-left', label = 'Top-left' },
                    { value = 'top', label = 'Top-center' },
                    { value = 'bottom-right', label = 'Bottom-right' },
                    { value = 'bottom-left', label = 'Bottom-left' },
                    { value = 'bottom', label = 'Bottom-center' }
                }
            }
        },
        values = {
            notifySound = settings.notifySound,
            notifyPosition = settings.notifyPosition
        },
        labels = {
            confirm = 'CONFIRM',
            cancel = 'CANCEL'
        }
    })

    if result then
        for key, value in pairs(result) do
            if defaults[key] ~= nil then
                saveSetting(key, value)
            end
        end
        lib.notify({
            type = 'success',
            title = 'Settings',
            description = 'Settings saved successfully',
            duration = 2000
        })
    end
end

loadSettings()

RegisterCommand('eslibsettings', function()
    openSettingsMenu()
end, false)

lib.getSetting = getSetting
lib.getAllSettings = getAllSettings
lib.openSettingsMenu = openSettingsMenu

exports('getSetting', getSetting)
exports('getAllSettings', getAllSettings)
exports('openSettingsMenu', openSettingsMenu)

return {
    getSetting = getSetting,
    getAllSettings = getAllSettings,
    openSettingsMenu = openSettingsMenu
}
