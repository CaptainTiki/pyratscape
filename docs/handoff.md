# PyratScape — Dev Handoff
**Date**: 2026-04-06
**Session**: Asteroid Splitting, Tractor Overhaul, Station Calling, Minimap, Starscape

---

## What Was Done This Session

### Asteroid Splitting
**`world/props/asteroid_node.gd`** — Full rewrite with size system:
- `AsteroidSize` enum: LARGE / MEDIUM / SMALL
- `split` signal (emits origin, child_size, child_count) replaces direct `mined_out` on LARGE/MEDIUM
- `mined_out` now only fires on SMALL (final destruction)
- Scale auto-configured per size: LARGE=1.0×, MEDIUM=0.55×, SMALL=0.3×
- Drop table per size: LARGE/MEDIUM drop 1-2 scrap bits (small pickup); SMALL drops 4-5 scrap chunk + 0-2 crystals
- `apply_tractor_drag()` added for tractor beam support

**`world/sector_spawner.gd`** — Handles `split` signal:
- Spawns 2-3 MEDIUM children from LARGE, 3-4 SMALL children from MEDIUM
- Children scattered ±2.5 units from origin
- `asteroids_remaining` adjusts correctly (parent -1, children +N)
- New `asteroid_split` signal emitted up to SectorController

**`world/sector_controller.gd`** — Wired `asteroid_split`:
- `on_asteroid_split()` adds 1.0 activity per split (vs 5.0 for full mine-out)

**`world/props/resource_pickup.gd`** — Bits vs Chunks visual:
- Pickups with amount ≤2 render at 0.5× mesh scale (bits)
- Pickups with amount ≥4 render at 1.0× mesh scale (chunks)

---

### Tractor Beam Overhaul
**`world/player/tractor_system.gd`** — Full rewrite:
- State machine: IDLE → CHARGING → LOCKED
- 80° cone (±40° from nose) — dot product filter, nothing outside cone can lock
- 1.5s lock-on delay with beam fading up from near-invisible → full brightness
- Swinging off target mid-charge resets to IDLE
- On LOCKED: pickups magnet to ship as before; asteroids get `apply_tractor_drag()` friction pull (4 u/s)
- All key params `@export`: `cone_half_angle_deg`, `lock_on_time`, `asteroid_pull_strength`
- Beam material duplicated per-instance in `initialize()` (called from PlayerShip._ready)

**`world/player/player_ship.gd`** — calls `tractor.initialize()` in `_ready()`

**`world/player/player_ship.tscn`** — TractorArea `collision_mask` bumped from 8 → 9 (picks up asteroids on layer 1)

---

### Station Calling (R Key)
**`project.godot`** — Added `call_station` input action (R key, physical keycode 82)

**`world/station_manager.gd`** — Bay state machine:
- `open_bay()` / `close_bay()` — opens a 25s docking window
- `_process()` counts down `_bay_timer`, emits `bay_closed` on timeout
- `get_bay_pull_force(player_pos)` — returns pull vector toward station (6 u/s, within 20 units) when bay open
- `bay_opened` / `bay_closed` signals
- All tunable via `@export`: `bay_duration` (25s), `bay_pull_strength` (6.0), `bay_pull_radius` (20.0)

**`world/sector_controller.gd`** — `try_call_or_open_bay()`:
- No station present → calls it in
- Station present, bay closed → opens bay
- Station present, bay open → resets timer
- `get_bay_pull_force()` delegates to StationManager

**`world/sector_reporter.gd`** — Bay messages: `bay_opened()`, `bay_extended()`, `bay_timed_out()`

**`world/player/ship_movement.gd`** — Added `external_velocity: Vector3` applied each frame then zeroed

**`world/player/player_ship.gd`** — R key fires `try_call_or_open_bay()`; bay pull force fed into `movement.external_velocity` each physics frame

---

### Minimap
**`ui/hud/minimap_display.gd`** — New `Control` subclass using `_draw()`:
- Redraws every frame via `queue_redraw()` in `_process()`
- Player = white forward-pointing chevron (rotates with ship heading)
- Enemies = red filled circles
- Asteroids = gray-blue dots, 3 sizes (4.5r / 2.8r / 1.6r)
- Station = green diamond, clamped to radar edge when out of range
- Two faint grid rings at 40% and 75% radius for depth reference
- `radar_range` export (default 55 world units)

**`ui/hud/hud.tscn`** — Replaced `MinimapLabel` placeholder with `MinimapDisplay` Control node

**`ui/hud/hud.gd`** — Wires `minimap.world` in `bind_world()`

---

### Starscape + Ground Removal
**`world/star_field.gd`** — New `Node3D` autobuilds 3 MultiMesh star layers on `_ready()`:
- y=-65: 600 stars, cool blue-white, spread 1400u (deep background, barely moves)
- y=-22: 220 stars, warm white, spread 900u (mid layer)
- y=-5:   80 stars, pure white, spread 500u (near layer, most parallax)
- All unshaded, shadow casting off, per-star scale variation 0.7–1.4×
- Fixed RNG seed (77142) — same starfield every run

**`world/world_root.tscn`** — Removed Ground StaticBody3D entirely (mesh + collision + sub-resources). Environment background set to pure black (mode=1). StarField node added.

---

## Current File State

### New files created this session
- `world/star_field.gd`
- `ui/hud/minimap_display.gd`

### Modified files
- `world/props/asteroid_node.gd`
- `world/sector_spawner.gd`
- `world/sector_controller.gd`
- `world/sector_reporter.gd`
- `world/props/resource_pickup.gd`
- `world/player/tractor_system.gd`
- `world/player/player_ship.gd`
- `world/player/player_ship.tscn`
- `world/station_manager.gd`
- `world/player/ship_movement.gd`
- `ui/hud/hud.gd`
- `ui/hud/hud.tscn`
- `world/world_root.tscn`
- `project.godot`

---

## What's Next (Priority Order)

### 1. Docking Menu UI
- Research tab, production tab, station health display
- Spend scrap/crystals on upgrades
- Current hook: `dock_sequence_finished` signal on SectorController fires when docking completes

### 2. Escape Pod on Death
- On hull destroyed: spawn escape pod at ship position instead of queue_free
- Pod drifts, no controls, 10-15s before "rescue"
- No save system yet — on pod death, reset to new game
- Current hook: `_on_hull_destroyed()` in `player_ship.gd`

### 3. Sector Map Improvements
- Enemy fleet movement between sectors (per-turn)
- Navigate button (confirm sector choice and redeploy)
- Skip Time button (advance enemy fleets, maybe trigger events)

### 4. Polish / Tuning Pass
- Minimap: consider showing pickup dots (small yellow/cyan)
- Tractor beam: visual charging FX on ship (glow pulse near muzzle?)
- Asteroid split: screen shake or camera bump on large split
- Station bay: visual indicator on station when bay is open (light/glow)

---

## Key Architecture Notes

- **Signal flow**: `sector_controller.sector_changed` → `world.world_state_changed` → `hud._refresh()` — both HUDs subscribe
- **Player access**: `world.sector_controller.player` (spawned dynamically, null before ACTIVE state)
- **GameData**: Autoload singleton — all cross-sector persistence (hull, scrap, crystals, upgrades)
- **Asteroid chain**: LARGE splits to MEDIUM (2-3), MEDIUM splits to SMALL (3-4), SMALL fires `mined_out`
- **Tractor**: IDLE→CHARGING(1.5s)→LOCKED; cone ±40°; resets if target leaves cone mid-charge
- **Bay pull**: applied via `movement.external_velocity` each physics frame; zeroed after `move_and_slide()`
- **Starfield**: purely visual Node3D, no gameplay coupling, fixed seed for consistency

---

## Known Placeholders / TODOs
- `PowerBar` in HUD: always 100% — power system not yet implemented
- `MissileLabel` in HUD: shows "MSSL --" — ammo system not yet implemented
- `OtherBar` in station panel: always 0% — awaiting third resource type
- Minimap: pickups not shown (could add as small dots later)
- Docking menu: not yet implemented (shows sector map immediately on dock)
