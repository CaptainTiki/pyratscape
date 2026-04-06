# Code Refactoring Handoff
_Last updated: 2026-04-05_

This document captures all identified refactoring opportunities in PyratScape, ready to pick up and execute. Items are ordered by priority and grouped by theme.

---

## 1. Extract: `Ship` Base Class 
**COMPLETED**

## 2. Extract: `DamageableComponent`
**COMPLETED**



## 3. Extract: `CollisionDamageHandler`
**COMPLETED**

## 4. Extract: `PickupSpawner`
**COMPLETED**

## 5. Flatten: `WorldRoot` Passthrough Layer
**COMPLETED**

## 6. Flatten: `SectorController` Passthrough Properties
**COMPLETED**

## 7. Simplify: `StationManager` Manual Tweening
**COMPLETED**

## 8. Simplify: Timer Countdown Pattern
**COMPLETED**

## 9. Simplify: Signal Connection Boilerplate in `SectorController.setup()`
**COMPLETED**

## 10. Expose: Magic Numbers as `@export` Variables
**COMPLETED**

## 11. Cleanup: Remove `PauseMenu` Script
**COMPLETED**

## 12. Cleanup: Standardize Resource Loading
**Files:** `system/prefabs.gd` vs. everywhere else

`prefabs.gd` uses `load()` with UID strings at runtime. Every other file uses `preload()` with explicit paths, which is validated at import time.

**Action:** Convert `prefabs.gd` to use `preload()`. UIDs are fine in `.tscn` files but fragile in GDScript `load()` calls — if a scene is reimported with a new UID the reference silently breaks.

---

