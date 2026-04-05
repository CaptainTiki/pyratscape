# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PyratScape** is a top-down 3D space arcade game built in Godot 4.6 (Forward Plus, D3D12, Jolt Physics). The player pilots a ship through node-based missions: mine asteroids, fight enemies, defend a station, collect resources, and buy upgrades between runs. A procedural node map connects missions with escalating difficulty.

## Running the Game

Open the project in Godot 4.6+ and press **F5** to run. The main scene is `system/main/main.tscn`. There are no build scripts or CLI commands—Godot handles compilation and export natively.

To export: **Project → Export** in the Godot editor.

## Architecture

### Scene/System Hierarchy

```
Main (system/main/)
└── GameRoot (system/game_root/)            ← instantiated on "Play"
    ├── WorldRoot (world/world_root/)       ← orchestrator + state machine
    │   ├── CameraRig (camera_rig.gd)      ← follows player or pans to station
    │   ├── EnemySpawner (enemy_spawner.gd) ← wave spawning + enemy tracking
    │   ├── ActivityTracker (activity_tracker.gd) ← threat/activity accumulation
    │   ├── StationManager (station_manager.gd)   ← deploy/dock/depart transitions
    │   ├── Actors/                         ← PlayerShip, EnemyShips
    │   ├── Projectiles/                    ← active projectiles
    │   └── Pickups/                        ← resource pickups
    └── GameHud (ui/hud/)
```

`Main` owns the top-level lifecycle: it instantiates `GameRoot` on game start and tears it down on return to menu. `GameRoot` owns fade transitions and holds references to `WorldRoot` and `GameHud`.

### WorldRoot Component Architecture

`WorldRoot` is a thin orchestrator that owns the `NodeState` state machine and coordinates four child components through signals. It has no `_process()` — all per-frame work runs in the components.

| Component | Responsibility | Key Signals |
|---|---|---|
| **CameraRig** | Smooth-follows player with lerp; pans to station when no player | (none — pure consumer) |
| **EnemySpawner** | Spawn timer, wave sizing, cap scaling, enemy lifecycle | `enemy_destroyed`, `wave_spawned` |
| **ActivityTracker** | Time-based + event-based activity accumulation, win condition | `activity_changed`, `run_completed` |
| **StationManager** | Deploy/dock/depart/inbound transitions, collision toggle, damage | `deploy_finished`, `dock_finished`, `inbound_finished`, `redeploy_finished` |

External code (enemies, asteroids, pickups) accesses WorldRoot via `get_tree().get_first_node_in_group("world_root")`. WorldRoot exposes facade properties (`enemies_remaining`, `activity`, `run_complete`) that delegate to components—keeping the external API stable.

### State Machine (WorldRoot)

```
DEPLOYING → ACTIVE → STATION_INBOUND → DOCKING → DOCKED → REDEPLOYING → DEPLOYING
```

- **DEPLOYING:** StationManager scales station in, asteroids spawn
- **ACTIVE:** Player spawned, station warps away, EnemySpawner + ActivityTracker active
- **STATION_INBOUND/DOCKING:** Win condition met, player calls station with F
- **DOCKED:** MainMenu overlay shows node map; player picks next node, then redeploys

Win condition: `enemies_remaining <= 0 AND activity >= 35`

### Node Map System

`NodeMapData` (`system/node_map/node_map_data.gd`) generates a connected graph of 14 map nodes on a jittered 4×4 grid. Each node has `enemy_fleet_size`, `asteroid_count`, `danger_level`, `has_poi`. Connections use MST + extra edges for loops. Nodes further down the map are more dangerous.

`NodeMap` (`ui/node_map/node_map.gd`) renders the map with `_draw()` — color-coded nodes, fleet dots (yellow/orange/red by danger), asteroid clusters, POI diamonds. Players click adjacent nodes to select, then deploy.

On redeploy, `WorldRoot._read_map_node_params()` reads the current node's data to set `spawn_cap_base`, `target_asteroid_count`, and `danger_level`. Enemy fleets shuffle ±1 each redeploy.

### Global State (GameData)

`GameData` (`system/game_data/game_data.gd`) is an autoloaded singleton holding all persistent run state: resources (scrap, crystals), player stats, station integrity, cleared run count, and the `NodeMapData` instance. Upgrade costs scale with `cleared_runs`.

### Key Signal Flow

```
ActivityTracker ──activity_changed──→ WorldRoot → world_state_changed → GameHud
ActivityTracker ──run_completed────→ WorldRoot (marks node cleared)
EnemySpawner ───enemy_destroyed───→ WorldRoot → ActivityTracker.add_activity
StationManager ─deploy_finished───→ WorldRoot (spawns player, starts spawner/tracker)
StationManager ─dock_finished─────→ WorldRoot → dock_sequence_finished → GameRoot (fade + overlay)
```

## Input Actions

| Action | Key | Effect |
|---|---|---|
| `move_up` | ↑ | Forward throttle; double-tap = boost (1.7×, 0.4s) |
| `move_down` | ↓ | Reverse (0.55× speed) |
| `move_left/right` | ←/→ | Rotation |
| `fire_primary` | Q | Twin cannons (12 dmg each, 0.22s cooldown) |
| `fire_secondary` | W | Missile (18 dmg, 0.6s cooldown; also used for mining) |
| `fire_tractor` | E | Tractor beam (magnetizes nearest resource within 7.5 units) |
| `interact` | F | Dock with station / call station when away |
| `cancel` | Esc | Return to main menu |

## Combat & Physics Notes

- All ships are `CharacterBody3D`, constrained to Y=1.25
- Projectiles are `Area3D`; they ignore their source body via an `ignore` reference
- The `is_mining` flag on `Projectile` determines whether it can damage `AsteroidNode`s
- Collision damage to ships scales with impact velocity (0.42× multiplier); ships bounce back at 35% impact speed
- Enemies attack the station directly if within 6 units (6 dmg/1.2s)

## Spawning & Difficulty

Enemy spawn cap: `min(spawn_cap_base + floor(activity / 18), 8)` — `spawn_cap_base` set by map node.
Wave size: `1 + floor(activity / 28)` clamped to [1, 3].
Activity rate scales by `0.5 + danger_level * 1.5`.
Asteroids spawn procedurally in a ring (10–28 units) with minimum spacing; count set by map node.
Upgrade costs scale with `GameData.cleared_runs` to increase difficulty across runs.
