# Test Commands for es_lib

## Quick Start

To enable the test menu, add the test file to your fxmanifest.lua:

```lua
client_scripts {
    'shared/init.lua',
    'client/notify.lua',
    'client/menu.lua',
    'client/debug_panel.lua',
    'tests/client/debug_commands.lua',
}
```

Then restart the resource and run `/eslib` in FiveM to open the test menu.

## Test Menu

The `/eslib` menu covers:

- Notifications (types, positions, persistent, sound, update/hide, helper methods)
- Progress bars (bar/circle, middle, cancelable, animations, props, control locks, API cancel)
- Menus (option types, callbacks, nested menus, setMenuOptions, input lock)
- Alert dialogs (confirmation, info, styled)
- Text UI (positions and custom styles)
- Debug panel (show/update/hide/status)
- Utilities (requestAnimDict, requestModel, getOpenMenu)

## Client Console Testing

You can also run tests directly from the FiveM client console (F8):

```lua
lib.notify({ type = 'success', title = 'Success', description = 'Works!' })
lib.progress({ label = 'Test', duration = 3000 })
lib.clearNotifications()
```

## Server-Side Testing

To test server notifications, add this to a server script:

```lua
RegisterCommand('es_test_server', function(source)
    TriggerClientEvent('es_lib:notify', source, {
        type = 'info',
        title = 'Server Notification',
        description = 'Sent from server!'
    })
end, true)
```

## Notes

- Test menu requires the resource to be running
- Use `/eslib` to open the test menu
- Progress bar can be cancelled with right-click if `canCancel = true`
- Persistent notifications stay visible until dismissed
- Notification positions: `top-right`, `top-left`, `top`, `bottom-right`, `bottom-left`, `bottom`
- Progress bar positions: `bottom`, `middle`
