# es_lib Optimization Guide (ox_lib Practices)

This guide focuses on patterns that keep `es_lib` fast and predictable.

## 1) Prefer event-driven design

- Use exported functions + net events.
- Avoid always-on threads. If a thread is needed, keep it sleeping (`Wait(250-1000)`) unless actively doing work.

Good:

- On notify/progress call → send **one** NUI message.

Avoid:

- Threads that poll UI state every frame.

## 2) Cache natives and identifiers

Client hot paths should not call these repeatedly:

- `PlayerPedId()`
- `PlayerId()`
- `GetPlayerServerId()`

Use a shared cache (already in `shared/init.lua`) and refresh at a fixed interval.

Rule of thumb:

- **Ped:** refresh ~100ms when needed.
- **Everything else:** refresh on events (player spawn, resource start) unless required.

## 3) NUI messages should be coarse-grained

- Send payloads like `{ action = 'notify:add', data = { ... } }`.
- Prefer **add/update/remove** actions over “replace whole list”.

This keeps JSON small and avoids large React re-renders.

## 4) Avoid allocations in loops

- Reuse tables where it’s safe.
- Prefer `local` variables.
- Precompute hashes (`joaat`) once per asset.

## 5) Keep exports stable and typed

- Use EmmyLua annotations for public APIs.
- Keep data shapes stable: adding new optional fields is ok; renaming/removing fields is breaking.

## 6) UI rendering: minimize churn

In `ui/app.js`:

- Keep a single `message` handler and route by `action`.
- When updating an item, update in-place by id (map once; avoid deep clones of large arrays).
- Clean up timers in `useEffect` cleanup.

## 7) Progressive backoff for asset loading

When waiting for assets:

- Use a timeout (default 5000ms).
- `Wait(0)` only while actively waiting for a short time; otherwise `Wait(10-50)`.

## 8) Fail fast

- Validate input types once.
- Use guard clauses.
- Return `false`/`nil` for failure and let callers decide what to do.

## Checklist for new modules

- No always-on `Wait(0)` loops.
- One-way data flow to UI with small messages.
- Clear cleanup paths (timers, dicts, models).
- `resmon` idle cost near zero.
