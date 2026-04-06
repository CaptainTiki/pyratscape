# PyratScape — Dev Handoff
**Date**: 2026-04-06
**Session**: Combat Rebalance + HUD Refactor

---

## What Was Done This Session

### Combat Rebalance (Phase 1A / 1B / 1C)

**`world/enemy_spawner.gd`** — All knobs now `@export` grouped in Inspector:
- `start_delay`: 5.0s (was hardcoded 3.5s)
- `spawn_interval_min`: 2.0s (was 0.8s) — players have breathing room
- `spawn_interval_activity_scale`: 0.04 (was 0.08) — half ramp speed
- `live_cap_max`: 6 (was 8)
- `activity_per_wave_size`: 42.0 (was 28.0) — slower escalation to 3-enemy waves

**`world/enemies/enemy_ship.gd`** — Also grouped, plus new behaviors:
- `move_speed`: 10.0 (was 13.0)
- `turn_speed`: 3.0 (was hardcoded 6.0) — sluggish turning, enemies overshoot
- `fire_cooldown`: 1.4s (was 1.0s)
- `projectile_damage`: 5.0 (was 8.0)
- `engage_range`: 18.0 (now exported)
- `preferred_range_variance`: ±2.0 — each enemy picks a slightly different orbit distance
- `engage_delay_min/max`: 0.5–1.5s — enemies in a wave don't all rush at once

**`world/health_component.gd`** — Added `damaged` signal (emitted on every hit)

**`world/player/hull_component.gd`** — Also emits `damaged` signal in its override

**`world/enemies/enemy_ship.gd`** — Hit flash + death explosion:
- Hit flash: body material duplicated per instance, tweens white → original (0.15s)
- Death explosion: programmatic sphere spawned at death position, scales 1→4 + fades (0.35s)

---

### HUD Refactor (Phase 2A–D)

**File structure:**
```
ui/hud/hud.tscn + hud.gd          ← Main game HUD (always visible during play)
ui/hud/debug_overlay.tscn + .gd   ← Debug overlay (F3 to toggle, hidden by default)
```

**`ui/hud/hud.tscn`** — Minimalist bar-based layout:
- **Ship panel** (top-left): Hull bar (red), Power bar (blue, placeholder 100%), Cargo bar (yellow, scrap+crystals/50 max), Missile label (placeholder "MSSL --")
- **Station panel** (top-right): STA status text, DOCK status text, Scrap bar (gold), Crystal bar (cyan), Other bar (green, future use)
- **Minimap panel** (bottom-right): 160×160 placeholder with "MINIMAP" label
- **DamageFlash**: Full-screen red ColorRect, flashes 30% opacity on player hit, fades over 0.4s

**`ui/hud/debug_overlay.tscn`** — Text-heavy overlay with all game state:
- Hull / Station, Scrap / Crystals / Enemies / Asteroids / Activity, Mission message, Keybind hints, Sector state
- **Does NOT touch `visible` in `_refresh()`** — visibility controlled by F3 only

**`system/game_root/game_root.gd`** — Wires both HUDs:
```gdscript
@onready var hud: Hud = $CanvasLayer/HUD
@onready var debug_overlay: DebugOverlay = $CanvasLayer/DebugOverlay
# F3 toggles debug_overlay.visible in _unhandled_input()
```

---

## Current File State

### New files created this session
- `ui/hud/hud.tscn` + `ui/hud/hud.gd`
- `ui/hud/debug_overlay.tscn` + `ui/hud/debug_overlay.gd`

### Orphaned (no longer referenced, safe to delete)
- `ui/hud/game_hud.tscn` + `ui/hud/game_hud.gd`
- `ui/hud/minimalist_hud.tscn` + `ui/hud/minimalist_hud.gd`

### Modified files
- `world/enemy_spawner.gd`
- `world/enemies/enemy_ship.gd`
- `world/health_component.gd`
- `world/player/hull_component.gd`
- `system/game_root/game_root.gd`
- `system/game_root/game_root.tscn`

---

## What's Next (Priority Order)

### 1. Asteroid Splitting + Pickup Variety (do together)
- Large → 2-3 Mediums → 3-4 Smalls → destroyed
- Drops at every stage, higher chance on final destruction
- **Bits** (1-2 units, small) vs **Chunks** (4-5 units, large) pickup variants
- Visual distinction: size scale, glow, rotation speed

### 2. Tractor Beam Overhaul
- Forward-facing 60-90° cone (not omnidirectional sphere)
- 1.5-2s lock-on delay with charging visual
- Friction drag on targeted asteroids
- Current file: `world/player/tractor_system.gd`

### 3. Station Calling (R key)
- R key calls station into docking mode, opens bay
- Projects a safe zone (Area3D) that auto-pulls ship toward dock
- 20-30s timer, auto-closes, re-press to reopen
- Current docking flow: `world/sector_controller.gd`, `world/station_manager.gd`

### 4. Minimap
- Replace placeholder with actual SubViewport radar
- Player = center, asteroids = size-coded dots, enemies = red, station = green

### 5. Medium Priority (later)
- Docking menu UI (research, production, station health)
- Escape pod on death (no save system yet, reset to new game on pod death)
- Sector map: enemy fleet movement, Navigate button, Skip Time button

---

## Key Architecture Notes

- **Signal flow**: `sector_controller.sector_changed` → `world.world_state_changed` → `hud._refresh()` — both HUDs subscribe to this
- **Player access**: `world.sector_controller.player` (spawned dynamically per sector, null before ACTIVE state)
- **GameData**: Autoload singleton — all cross-sector persistence lives here (hull, scrap, crystals, upgrades)
- **Enemy spawner**: Inspector-tunable via `@export_group` — tweak spawn timing without touching code
- **Enemy ship**: Inspector-tunable via `@export_group` — movement, combat, and engagement params all exposed

---

## Known Placeholders / TODOs
- `PowerBar` in HUD: always 100% — real power system not yet implemented
- `MissileLabel` in HUD: shows "MSSL --" — ammo system not yet implemented
- `OtherBar` in station panel: always 0% — awaiting third resource type
- Minimap: placeholder panel only
- Missile ammo: decided to be limited pool, but tracking not wired yet
