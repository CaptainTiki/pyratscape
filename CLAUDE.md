# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PyratScape** is a 3D space action/roguelike game built with Godot 4.6 (Forward Plus renderer, Jolt Physics, D3D12 on Windows). Players pilot a ship to mine asteroids, fight enemies, and manage upgrades across a handcrafted world built of interconnected sectors.

## Running the Project

This is a native Godot project — there are no build scripts or test frameworks. To run:
- Open `project.godot` in Godot 4.6 Editor and press Play
- Or from CLI: `godot --path . --editor` to open the editor, `godot --path .` to run headless

The main scene resolves via UID `uid://2alhfho5j7vs` (defined in `project.godot`).

## Architecture

The project uses a layered scene hierarchy with signal-driven communication:

```
Main (system/main/)
├── MenuManager (system/menu_manager/) — UI state machine, owns all menus
└── GameRoot (system/game_root/) — instantiated on play start
    ├── WorldRoot (world/world_root.gd) — game simulation hub
    │   ├── SectorController — sector lifecycle state machine
    │   ├── PlayerShip, EnemyShips, Asteroids — actors
    │   ├── EnemySpawner — wave management
    │   ├── ActivityTracker — win condition tracking
    │   └── StationManager — docking sequences
    └── GameHUD (ui/hud/) — in-game overlay
```

### Key Systems

**GameData** (`system/game_data/game_data.gd`) — Autoload singleton. Persists all cross-sector state: player resources (scrap, crystals), hull/weapon upgrades, current sector, and the `SectorMapData` object.

**SectorController** (`world/sector_controller.gd`) — State machine driving the sector lifecycle:
`DEPLOYING → ACTIVE → DOCKING → DOCKED → REDEPLOYING`
Spawns asteroids and player on deploy; triggers station inbound/dock animations on win.

**ActivityTracker** (`world/activity_tracker.gd`) — Tracks "heat" from kills and mining. Win condition fires when activity ≥ 35 and no enemies remain.

**EnemySpawner** (`world/enemy_spawner.gd`) — Scales wave sizes by activity level and sector danger rating (1–8 enemies live at a time).

**SectorMapData** (`system/sector_map/sector_map_data.gd`) — Generates a procedural 4×4 grid of 14 sectors with danger levels and connections. Tracks completion state per sector.

**MenuManager** → instantiates menus on demand; `Main` calls into it to show/hide menus and reads signals to start/redeploy the game.

**GameRoot** (`system/game_root/`) — Binds the HUD to the world, wires up all cross-system signals, and manages screen fade transitions between sectors.

### Signal Flow (Core Loop)

```
PlayerInput → PlayerShip._physics_process()
  → asteroid mine / enemy kill → ActivityTracker (updates activity)
    → SectorController checks win condition
      → StationManager plays dock animation
        → GameData saves state
          → MenuManager shows StationMenu / SectorMapMenu
            → player selects next sector → Main.redeploy_current_game()
```

### Input Bindings (defined in project.godot)

| Action | Key |
|---|---|
| Movement | Arrow keys |
| Fire primary | Q |
| Fire secondary | W |
| Tractor beam | E |
| Interact/Dock | F |
| Menu/Cancel | Escape |

## Code Conventions

- All scripts use GDScript 4.x (`class_name` declarations are common)
- Scene files (`.tscn`) and scripts (`.gd`) are co-located by feature under `system/`, `world/`, and `ui/`
- Prefabs/scene paths are centralized in `system/prefabs.gd`
- Node UID references are used instead of string paths for scene instantiation

- ALWAYS use double quotes " " for all strings
- NEVER escape double quotes with backslashes (\") inside code blocks.
- NEVER output JSON, never wrap code in extra quotes, never add escape sequences for quotes.
- When showing dictionary literals, arrays, or any code containing strings, output the code EXACTLY as it should appear in a .gd file.

- Example of CORRECT output for this pattern:
data[slot] = {
    "slot_type": ship_config[slot].slot_type if ship_config[slot] else "",
    "icon_color": ship_config[slot].icon_color.to_html(false) if ship_config[slot] else ""
}
