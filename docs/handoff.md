# PyratScape — Dev Handoff
**Date**: 2026-04-07
**Session**: Escape Pod / Ship Hull Swap

---

## What Was Done This Session

### Escape Pod via Hull Swap
The ship no longer spawns a separate node on death. Instead, `PlayerShip` persists and calls `switch_to_pod()`, swapping visuals, collision, health, and disabling weapons/tractor. This avoids breaking the HUD, minimap, resource pickups, and enemy targeting — all of which are typed to `PlayerShip`.

**`world/player/ship_hull_config.gd`** — New `Resource` subclass:
- `@export_group` sections: Identity, Dimensions, Stats, Systems, Visual
- `is_escape_pod`, `collision_radius/height`, `max_health`, `speed_multiplier`, `has_weapons`, `has_tractor`, `ship_visual_visible`, `pod_visual_visible`
- First concrete step toward the future ship component system

**`world/player/player_ship.tscn`** — Visual groups added:
- `ShipVisual` (Node3D wrapper, visible=true) — Body, WingLeft, WingRight, Engine moved under it
- `PodVisual` (Node3D, visible=false) — PodBody (orange SphereMesh r=0.4) + PodEngine (glowing orange BoxMesh)

**`world/player/player_ship.gd`** — Hull swap logic:
- `_in_pod_mode: bool` flag
- `switch_to_pod()` — swaps visuals, resizes collision to (r=0.45, h=1.2), resets health to 40/40, scales speed ×0.85, zeros tractor_active
- `_on_hull_destroyed()` — disconnects signal, calls `switch_to_pod()`, reconnects to `_on_pod_destroyed()`
- `_on_pod_destroyed()` — game-over message + queue_free
- `_physics_process()` — skips `weapons.tick()` and `tractor.tick()` when `_in_pod_mode`

**`system/game_data/game_data.gd`** — Hull tracking:
- `player_ship_max_hull: int = 100` — permanent max; only changed by hull upgrades
- `restore_ship_hull()` — resets `player_max_hull` and `player_hull` to `player_ship_max_hull`
- `buy_hull_upgrade()` now increments both `player_ship_max_hull` and `player_max_hull`

**`world/sector_spawner.gd`** — Calls `GameData.instance.restore_ship_hull()` before instantiating new ship, so pod-mode GameData values don't bleed into the next deploy.

**`world/sector_controller.gd`** — Reverted `player` back to `PlayerShip` read-only getter (was temporarily `ShipEntity` during failed EscapePod-node attempt).

---

## Current File State

### New files created this session
- `world/player/ship_hull_config.gd`

### Modified files
- `world/player/player_ship.gd`
- `world/player/player_ship.tscn`
- `system/game_data/game_data.gd`
- `world/sector_spawner.gd`
- `world/sector_controller.gd`

### Deleted files
- `world/player/escape_pod.gd` (superseded by hull-swap approach)
- `world/player/escape_pod.tscn`

---

## What's Next (Priority Order)

### 1. Docking Menu UI
- Research tab, production tab, station health display
- Spend scrap/crystals on upgrades
- Current hook: `dock_sequence_finished` signal on SectorController fires when docking completes

### 2. Sector Map Improvements
- Enemy fleet movement between sectors (per-turn)
- Navigate button (confirm sector choice and redeploy)
- Skip Time button (advance enemy fleets, maybe trigger events)

### 3. Polish / Tuning Pass
- Minimap: consider showing pickup dots (small yellow/cyan)
- Tractor beam: visual charging FX on ship (glow pulse near muzzle?)
- Asteroid split: screen shake or camera bump on large split
- Station bay: visual indicator on station when bay is open (light/glow)

---

## Key Architecture Notes

- **Hull swap pattern**: `PlayerShip` is permanent; `switch_to_pod()` changes its config. Extending to full componentization means replacing `_in_pod_mode` flag with a `current_hull: ShipHullConfig` slot, then adding weapon/tractor/generator/shield slots.
- **GameData hull fields**: `player_ship_max_hull` = permanent (upgrade target); `player_max_hull` = operational (temporarily lowered for pod). `restore_ship_hull()` syncs them before redeploy.
- **Signal flow**: `sector_controller.sector_changed` → `world.world_state_changed` → `hud._refresh()` — both HUDs subscribe
- **Player access**: `world.sector_controller.player` (getter delegates to `spawner.player`)
- **GameData**: Autoload singleton — all cross-sector persistence
- **Asteroid chain**: LARGE splits to MEDIUM (2-3), MEDIUM splits to SMALL (3-4), SMALL fires `mined_out`
- **Tractor**: IDLE→CHARGING(1.5s)→LOCKED; cone ±40°; resets if target leaves cone mid-charge
- **Bay pull**: applied via `movement.external_velocity` each physics frame

---

## Known Placeholders / TODOs
- `PowerBar` in HUD: always 100% — power system not yet implemented
- `MissileLabel` in HUD: shows "MSSL --" — ammo system not yet implemented
- `OtherBar` in station panel: always 0% — awaiting third resource type
- Minimap: pickups not shown
- Docking menu: not yet implemented (shows sector map immediately on dock)
- Pod mode: no visual death explosion on ship destroy (just swaps mesh)
- Pod mode: no screen shake or fanfare on hull destruction
