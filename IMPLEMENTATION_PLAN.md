# World Simulation Implementation Plan

**Status:** Initial MVP Phase
**Date:** 2026-04-07
**Scope:** Dynamic sector-based enemy simulation with resource tracking and time advancement

---

## Overview

The world simulation will drive a living, dynamic sector map where:
- Enemies move between sectors and accumulate at the player's location
- Resources deplete as enemies mine them (finite per sector)
- Factories produce new enemy ships over time
- Time advances during gameplay, sector navigation, and skip-time actions
- If enemies exceed a threshold (10) at the player's station, the player is forced into combat

---

## Phase 1: MVP (Current Implementation)

### Architecture

#### 1. **WorldSimulation** (`world/world_simulation/world_simulation.gd`)
- Child of `WorldRoot`
- Manages simulation ticks and time advancement
- Drives enemy AI logic (simple random movement in MVP)
- Exposes signals: `simulation_ticked`, `world_time_advanced`

**Key properties:**
```gdscript
@export var simulation_tick_interval: float = 0.1  # seconds
var game_time_minutes: float = 0.0  # accumulated game time
var enemies_at_station: int = 0  # enemies at player's current sector
```

**Key methods:**
```gdscript
func advance_time_minutes(minutes: float) -> void  # called on skip/nav
func get_enemies_at_station() -> int
func get_sector_resources(sector_id: int) -> int
```

---

#### 2. **EnemyForces** (`world/world_simulation/enemy_forces.gd`)
- RefCounted data structure tracking all enemies across sectors
- Replaces the need to track `SectorMapData.enemy_fleet_size` as static values
- Persisted in `GameData` (reset on new game)

**Structure:**
```gdscript
class SectorForces:
    var sector_id: int
    var available_resources: int  # finite pool per sector
    var miner_count: int          # mining ships
    var fighter_count: int        # combat ships
    var factory_count: int        # production facilities
    var enemy_ships_moving_here: int  # in transit to this sector

var sectors: Dictionary[int, SectorForces]  # sector_id → SectorForces
var total_game_time_minutes: float  # global time tracker
```

**Key methods:**
```gdscript
func get_enemies_in_sector(sector_id: int) -> int
func add_resources_to_sector(sector_id: int, amount: int) -> void
func consume_resources_in_sector(sector_id: int, amount: int) -> int
func add_enemy_to_sector(sector_id: int, enemy_type: String) -> void
func remove_enemy_from_sector(sector_id: int) -> void
func reset_for_new_game(sector_count: int) -> void
```

---

#### 3. **Integration Points**

**SectorMapData** (`system/sector_map/sector_map_data.gd`):
- Remove static `enemy_fleet_size` field (it's now dynamic in `EnemyForces`)
- Add `available_resources: int` field to `SectorData`
- Keep `danger_level` for future AI difficulty scaling

**GameData** (`system/game_data/game_data.gd`):
- Add: `var enemy_forces: EnemyForces = null`
- Initialize in `reset_for_new_game()`

**WorldRoot** (`world/world_root.gd`):
- Add `WorldSimulation` as a child node
- Wire up time advancement signals from menus/navigation

**SectorController** (`world/sector_controller.gd`):
- On `begin_sector_cycle()`: query `EnemyForces` for enemies at this sector, pass to spawner
- On sector exit (docking): save remaining alive enemies back to `EnemyForces`
- Check forced deployment: if enemies at station ≥ 10, auto-deploy

**EnemySpawner** (`world/enemy_spawner.gd`):
- Accept an initial enemy count from `SectorController` (instead of `enemy_fleet_size`)
- Spawn that many enemies at deploy (may be 0 if no enemies in the sector)
- Continue spawning as activity increases (existing behavior)

**MenuManager** / **SectorMapMenu**:
- Hook "skip time" button to `WorldSimulation.advance_time_minutes(5.0)`
- Hook sector navigation to `WorldSimulation.advance_time_minutes(5.0)` + animation

---

### Time Math

**Assumptions:**
- First-sector baseline: 15–20 min to clear with minimal interruption
- Want 2–3 enemy waves (3–4 ships each) during that time
- Sector navigation/skip time = ~5 min game time
- Simulation tick interval = 0.1s real-time

**Derived values:**
- Enemy waves spawn ~6–10 min apart (goal: ~2–3 waves in 15–20 min)
- 5 min game time = 50 ticks at default interval
- Factory production: 1 ship per 2–5 min = 1 ship per 20–50 ticks

**Adjustable parameters:**
```gdscript
@export var enemy_wave_interval_min_minutes: float = 6.0
@export var enemy_wave_interval_max_minutes: float = 10.0
@export var factory_production_time_minutes: float = 3.5  # avg of 2-5
@export var initial_resources_per_sector: int = 1800  # 15-20 asteroids × ~100 scrap
@export var enemy_mining_rate: float = 2.0  # scrap per tick
@export var enemy_forced_deploy_threshold: int = 10
```

---

### MVP Logic (Random, Simple)

#### Enemy Movement (Phase 1)
- Each tick, random sectors "request" ships
- Random sectors send ships to other sectors (1–2 per tick)
- Ships move over time (represented as "in transit" counter)
- When they arrive, they're added to the destination

#### Resource Depletion
- Miners in a sector consume resources at a fixed rate (e.g., 2 scrap/tick)
- When resources hit 0, miners leave or idle

#### Factory Production
- Each factory tick down a production timer
- Every 2–5 min (random), spawn 1 new fighter ship in its sector

#### Forced Deployment Check
- Each tick: if enemies at player's station ≥ 10, emit `forced_deploy_required` signal
- `SectorController` catches this and auto-deploys player to combat

---

### File Structure

```
world/
├── world_root.gd (existing, add WorldSimulation child)
├── sector_controller.gd (existing, integrate enemy_forces queries)
├── enemy_spawner.gd (existing, read enemy count from sector)
├── world_simulation/
│   ├── world_simulation.gd (NEW — main simulation driver)
│   ├── enemy_forces.gd (NEW — data structure)
│   └── fleet_mission.gd (FUTURE — intent/mission state)
├── enemies/
│   └── enemy_ship.gd (existing)

system/
├── game_data/
│   └── game_data.gd (existing, add enemy_forces reference)
├── sector_map/
│   └── sector_map_data.gd (existing, remove static enemy_fleet_size)
└── menu_manager/
    └── (existing, hook time advancement)
```

---

## Phase 2: Future Enhancements (NOT In MVP)

### Enemy AI & Intent System
- Fleet state machine: `ACCUMULATE` → `MINE` → `REQUEST_HELP` → `MOVE`
- Sectors calculate "need" based on resource levels and enemy pressure
- Fleets respond intelligently to requests
- Pathfinding via sector graph (Dijkstra for multi-hop routes)

### Boss Ships & Power Levels
- Rare enemy spawns (low % chance per factory production)
- "Power level" system: each enemy type has a combat value
  - Fighter = 1 point
  - Boss = 5+ points
  - Threshold stays at 10 points (not 10 ships)
- Boss appearance ties into narrative (eventual boss raids)

### Factories & Mining Ships as Entities
- Factories are long-lived, move slowly between sectors (warp jumps rare)
- Mining ships request supply runs to factories
- Factories can be destroyed to disrupt enemy production
- Player strategy: raid factories vs. farm resources

### Resource Replenishment
- Asteroids respawn after X time (slow cycle, won't happen in one sector visit)
- Cosmic events introduce new resources (procedural)
- Ancient ruins / anomalies = one-time jackpot resources

### Production & Research Systems
- Player can spend resources on upgrades/research
- Research & production consume game time (tracked via `game_time_minutes`)
- e.g., "Hull upgrade: 15 min to complete" → use skip time 3× to finish

### Persistence & Save System
- `EnemyForces` persists across sector changes (in `GameData`)
- Save/load hooks to serialize `game_time_minutes` and `enemy_forces` state
- (Implement when save manager is added)

---

## Implementation Checklist (MVP Only)

- [ ] Create `enemy_forces.gd` with basic data structure
- [ ] Create `world_simulation.gd` with tick loop and time advancement
- [ ] Extend `SectorMapData.SectorData` with `available_resources: int`
- [ ] Update `GameData` to hold and reset `enemy_forces`
- [ ] Update `SectorController` to query `enemy_forces` on deploy and save on exit
- [ ] Update `EnemySpawner` to accept initial enemy count (instead of reading `enemy_fleet_size`)
- [ ] Implement random enemy movement logic in `WorldSimulation`
- [ ] Implement resource consumption (mining) in `WorldSimulation`
- [ ] Implement factory production in `WorldSimulation`
- [ ] Hook time advancement into menu navigation and skip-time button
- [ ] Implement forced deployment check (enemies ≥ 10 at station)
- [ ] Test: sector entry, time advancement, enemy spawning, resource depletion
- [ ] Playtest and gather feedback on pacing/difficulty

---

## Open Questions / Future Tweaks

1. **Sector graph connectivity**: Should enemies prefer adjacent sectors or move randomly? (MVP: random)
2. **Enemy types**: Are there subtypes (fast fighters, slow miners, etc.) or just "enemy"? (MVP: generic for now)
3. **Station location**: Is the station always stationary on the map, or can it move between sectors? (MVP: stationary)
4. **Multiple factories**: Should there be multiple factories across the map or just one? (MVP: distribute based on danger)
5. **Visual feedback on map**: Which details should flash/color-change? (Will be addressed in map UI phase)

---

## Notes

- All time values are in **game minutes** (not real-time). Simulation ticks convert via the tick interval.
- `game_time_minutes` is global and never resets during a run (resets on new game).
- Enemy instantiation in sectors remains as real 3D actors; the simulation tracks abstract enemy counts.
- Resource depletion is a soft cap (simulation won't spawn enemies if sector is empty).
