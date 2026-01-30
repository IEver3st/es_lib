# es_lib Module Template (ox_lib-ish)

Use this when adding a new module under `client/`, `server/`, or `shared/`.

## Goals

- Small API surface
- Predictable performance
- Clean teardown
- Clear data contracts

## File skeleton

```lua
--[[
    es_lib - <module name>
    <1 line purpose>
]]

lib = lib or {}

-- ============================================================================
-- Types
-- ============================================================================

---@class ExampleData
---@field id string
---@field label string

-- ============================================================================
-- Locals
-- ============================================================================

local someLocal = 0

-- ============================================================================
-- Public API
-- ============================================================================

---@param data ExampleData
---@return boolean ok
function lib.example(data)
    if type(data) ~= 'table' then
        return false
    end

    -- do work
    return true
end

exports('example', lib.example)

return lib
```

## Naming and exports

- Implement as `function lib.<name>(...)`.
- Export it: `exports('<name>', lib.<name>)`.
- Keep names short and explicit (similar to `ox_lib`).

## Client vs server boundaries

- Client modules can talk to NUI (`SendNUIMessage`).
- Server modules should not assume UI exists.
- Shared modules should avoid FiveM-only natives when possible.

## Cleanup rules

If your module allocates:

- Threads → add control flags to stop work.
- Timers → store handles and clear them.
- Asset dicts/models → release them.

## Performance rules

- No polling loops unless feature is active.
- Avoid per-player ticks on server.
- Keep payloads small when sending events/messages.
