# es_lib Performance Targets

This project is modeled after `ox_lib` in spirit: small surface area, predictable costs, and safe-by-default performance.

## Targets (what we optimize for)

### Client

- **Idle cost:** ~0.00ms when no UI is visible and no features are active.
- **Notification spam:** 10 notifications/sec should not stutter the frame.
- **Progress bar:** UI updates should be animation-driven (CSS/RAF), not per-frame Lua.
- **No hot-path allocations:** avoid building large tables/strings in tight loops.

### Server

- **No per-player loops on tick:** avoid `while true do Wait(0)` patterns.
- **Bounded work per event:** validate inputs, then do constant or small-bounded work.

### NUI

- **Single message listener:** one `window.addEventListener('message')` entrypoint.
- **Minimal re-renders:** batch state updates; avoid deep object churn.
- **No heavy timers:** prefer CSS keyframes or `requestAnimationFrame` for animations.

## How to measure

- **Client:** `resmon 1` and watch `es_lib` while idle and during spam.
- **NUI:** Chrome devtools performance tab (via NUI devtools) while spamming notifications.
- **Server:** `txAdmin`/console performance metrics; avoid large event fan-out.

## Red flags (avoid)

- Tight loops with `Wait(0)` that always run.
- Calling `PlayerPedId()`/`PlayerId()` repeatedly in hot paths.
- Sending NUI messages every frame.
- Rebuilding big UI arrays when a single item changes.

## Practices (ox_lib-style)

- Prefer **event-driven** logic over tick-driven logic.
- Cache frequently used values (ped, ids) but refresh at a sane interval.
- Keep APIs small and composable; avoid “do everything” functions.
- Keep serialization small: send only what the UI needs.
