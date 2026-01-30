--[[
    Everest Lib (es_lib)
    Lightweight UI & Cross-Script Interface
    
    Fast. Minimal. Essential.
    
    Module-based architecture: modules are lazy-loaded when accessed.
    Other resources include `@es_lib/init.lua` in shared_scripts to use lib.
]]

fx_version 'cerulean'
game 'gta5'

name 'es_lib'
author 'Everest Studios'
version '2.0.0'
description 'Lightweight UI and utility library for the Everest ecosystem (module-based)'

-- Internal initialization for es_lib resource itself
shared_script 'resource/init.lua'

-- Client utility scripts (register exports for external resources using exports.es_lib:)
client_scripts {
    'client/utils.lua',
    'client/debug_panel.lua',
}

-- Test commands (only loaded internally)
client_script 'tests/client/debug_commands.lua'

-- UI files
ui_page 'ui/index.html'

-- Files available for LoadResourceFile (lazy-loaded modules + UI)
files {
    -- External init for other resources
    'init.lua',
    
    -- UI assets
    'ui/index.html',
    'ui/style.css',
    'ui/app.js',
    
    -- Client modules
    'imports/notify/client.lua',
    'imports/callback/client.lua',
    'imports/menu/client.lua',
    'imports/radial/client.lua',
    'imports/zones/client.lua',
    'imports/points/client.lua',
    'imports/raycast/client.lua',
    'imports/getters/client.lua',
    'imports/disablecontrols/client.lua',
    'imports/help/client.lua',
    'imports/settings/client.lua',
    
    -- Server modules
    'imports/notify/server.lua',
    'imports/callback/server.lua',
    
    -- Shared modules
    'imports/timer/shared.lua',
    'imports/waitFor/shared.lua',
    'imports/utils/shared.lua',
}

lua54 'yes'

-- Provide the init.lua for external resources to use
-- Usage in other resources: shared_script '@es_lib/init.lua'
