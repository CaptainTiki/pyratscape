# Code Refactoring Handoff
_Last updated: 2026-04-05_

This document captures all identified refactoring opportunities in PyratScape, ready to pick up and execute. Items are ordered by priority and grouped by theme.

---

## 1. Extract: `Ship` Base Class
**Files affected:** `world/player/player_ship.gd`, `world/enemies/enemy_ship.gd`

PlayerShip and EnemyShip share significant logic with no common parent:
- Projectile spawning
- Fire cooldown management
- Damage handling / death
- Pickup spawning on death
- `projectile_parent` node reference

**Action:** Create `world/ship_entity.gd` as a base `CharacterBody3D` subclass. Move shared logic there. PlayerShip and EnemyShip extend it and override only what differs (AI vs. player input, hull sync to GameData, etc.).

---

## 2. Extract: `DamageableComponent`
**Files affected:** `world/player/hull_component.gd`, `world/enemies/enemy_ship.gd`, `world/props/asteroid_node.gd`

All three implement the same pattern independently:
```gdscript
health = maxi(0, health - amount)
if health <= 0:
    _on_destroyed()
```

**Action:** Create `world/damageable_component.gd` as a `Node` component:
```gdscript
class_name DamageableComponent
signal destroyed
@export var max_health: int = 100
var health: int

func apply_damage(amount: int) -> void:
    health = maxi(0, health - amount)
    if health <= 0:
        destroyed.emit()
```
Parent nodes add it as a child, connect to `destroyed`, and handle their own death behavior. `hull_component.gd` may be removable entirely once this exists.

---

## 3. Extract: `CollisionDamageHandler`
**Files affected:** `world/player/ship_movement.gd` (lines 66–92), `world/enemies/enemy_ship.gd` (lines 58–71)

Both ships implement per-frame slide collision checking with a cooldown timer and identical damage formula:
```gdscript
# Both compute:
maxi(1, int(round(velocity.length() * 0.2)))
```
The only difference is the scale constant (player uses 0.42, enemy uses 0.2 — should be normalized).

**Action:** Create `world/collision_damage_handler.gd` as a `Node` component:
```gdscript
class_name CollisionDamageHandler
@export var damage_scale: float = 0.2
@export var cooldown: float = 0.3
var _timer: float = 0.0

func process_collisions(body: CharacterBody3D, delta: float) -> void:
    # shared cooldown + slide collision loop
```
Both ships add this as a child node and remove their inline collision logic.

---

## 4. Extract: `PickupSpawner`
**Files affected:** `world/enemies/enemy_ship.gd` (lines 96–111), `world/props/asteroid_node.gd` (lines 30–45)

Both scatter `ResourcePickup` instances at death with randomized positions and call `world.register_pickup()`. The amounts differ but the spawning logic is identical.

**Action:** Create `world/pickup_spawner.gd` as a static helper or `Node` component:
```gdscript
class_name PickupSpawner

static func spawn(world: WorldRoot, origin: Vector3, scrap: int, crystals: int) -> void:
    # shared instantiation + scatter + register loop
```
Both `_spawn_pickups()` methods become one-liners calling this.

---

## 5. Flatten: `WorldRoot` Passthrough Layer
**File:** `world/world_root.gd`

8 properties and 5 methods are pure forwarding with zero added behavior:
```gdscript
var player: PlayerShip:
    get: return sector_controller.player if sector_controller else null

func try_interact_at_station() -> bool:
    return sector_controller.try_interact_at_station()
# ... etc.
```
This creates a `WorldRoot → SectorController → Spawner` 3-hop chain for trivial reads.

**Action:** Expose `sector_controller` directly as a typed property on `WorldRoot`. Callers (primarily `game_root.gd` and `game_hud.gd`) access it directly. Remove the ~30 lines of forwarding code.

---

## 6. Flatten: `SectorController` Passthrough Properties
**File:** `world/sector_controller.gd` (lines 17–31)

Same forwarding pattern one level deeper — `player`, `asteroids_remaining`, `enemies_remaining` just read from child nodes.

**Action:** Once WorldRoot is flattened (item 5), evaluate whether these getters are still needed or if callers can reference the sub-nodes directly (spawner, enemy_spawner). If kept, no change needed — but they should not be wrapped again at WorldRoot level.

---

## 7. Simplify: `StationManager` Manual Tweening
**File:** `world/station_manager.gd`

The state machine manually lerps scale/position using a countdown timer and a handwritten cubic ease:
```gdscript
var t: float = 1.0 - (transition_timer / transition_duration)
var eased: float = 1.0 - pow(1.0 - t, 3.0)
station.scale = start_scale.lerp(target_scale, eased)
```
This is ~40 lines that Godot's Tween API handles natively.

**Action:** Replace each transition block with a `Tween`:
```gdscript
var tw := create_tween()
tw.tween_property(station, "scale", target_scale, duration)\
  .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
tw.finished.connect(_on_transition_done)
```
Removes `transition_timer`, `transition_duration`, `start_scale`, and all manual lerp logic.

---

## 8. Simplify: Timer Countdown Pattern
**Files:** `enemy_ship.gd`, `ship_movement.gd`, `weapon_system.gd`, `activity_tracker.gd`, `enemy_spawner.gd`, `station_manager.gd`

The pattern `timer = maxf(0.0, timer - delta)` / `if timer > 0.0: return` appears 15+ times.

**Option A (minimal):** Add a static helper to a utility file:
```gdscript
static func tick(timer: float, delta: float) -> float:
    return maxf(0.0, timer - delta)
```

**Option B (preferred):** Replace float timers with Godot `Timer` nodes where the cooldown semantics are clear and one-shot. This is more idiomatic and removes the `_process` polling entirely for fire cooldowns.

---

## 9. Simplify: Signal Connection Boilerplate in `SectorController.setup()`
**File:** `world/sector_controller.gd` (lines 40–57)

8 consecutive guard-connect blocks:
```gdscript
if not station_manager.deploy_finished.is_connected(on_station_deploy_finished):
    station_manager.deploy_finished.connect(on_station_deploy_finished)
```

**Action:** Move connections to `_ready()` (they only need to connect once). Remove the `is_connected` guards — they exist because `setup()` can be called multiple times, which is the real issue to fix.

---

## 10. Expose: Magic Numbers as `@export` Variables
**Files:** `world/enemy_spawner.gd`, `world/activity_tracker.gd`

Tuning values are hardcoded:
- `EnemySpawner`: `18.0`, `4.5`, `0.08`, `28.0`, `24.0`, `34.0`
- `ActivityTracker`: `0.5`, `1.5`, `0.55`, `0.055`, win threshold `35.0`

**Action:** Promote to `@export` variables with sensible defaults. This makes balancing possible from the editor without code changes, and documents intent via variable names:
```gdscript
@export var win_activity_threshold: float = 35.0
@export var activity_time_scale: float = 0.055
@export var spawn_interval_base: float = 4.5
```

---

## 11. Cleanup: Remove `PauseMenu` Script
**File:** `ui/menus/pause_menu/pause_menu.gd`

The file contains only `extends Menu` — zero additional logic. The scene can use `menu.gd` directly as its script, or pause-specific behavior can be added inline when needed.

---

## 12. Cleanup: Standardize Resource Loading
**Files:** `system/prefabs.gd` vs. everywhere else

`prefabs.gd` uses `load()` with UID strings at runtime. Every other file uses `preload()` with explicit paths, which is validated at import time.

**Action:** Convert `prefabs.gd` to use `preload()`. UIDs are fine in `.tscn` files but fragile in GDScript `load()` calls — if a scene is reimported with a new UID the reference silently breaks.

---

## Execution Order (Recommended)

| Step | Item | Reason |
|------|------|--------|
| 1 | DamageableComponent (#2) | Self-contained, no dependencies, immediate payoff |
| 2 | CollisionDamageHandler (#3) | Self-contained, removes bug-prone duplication |
| 3 | PickupSpawner (#4) | Self-contained, easy win |
| 4 | Ship base class (#1) | Depends on #2 and #3 being done first |
| 5 | Flatten WorldRoot (#5 + #6) | Simplifies all future reads; do before HUD/GameRoot changes |
| 6 | StationManager tweening (#7) | Isolated, no cross-system impact |
| 7 | Magic number exports (#10) | Low risk, high tuning value |
| 8 | Timer pattern (#8) | Do last — pervasive change, easy to scope wrong |
| 9 | Signal boilerplate (#9) | Low value, do opportunistically |
| 10 | PauseMenu + prefabs cleanup (#11, #12) | Trivial, do anytime |
