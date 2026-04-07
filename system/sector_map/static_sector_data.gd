extends Resource
class_name StaticSectorData

# A single hand-authored sector node in a static world.
# Lives inside a StaticWorldData resource. Labels and counts are
# intentionally explicit so tuning + tests can reference them by name.

@export var id: int = 0
@export var display_name: String = ""
@export var map_position: Vector2 = Vector2.ZERO

@export_group("Starting State")
@export var starting_fighters: int = 0
@export var starting_miners: int = 0
@export var starting_resources: int = 1800
@export var asteroid_count: int = 5

@export_group("Role Flags")
@export var is_factory: bool = false
@export var is_player_start: bool = false
@export var is_enemy_home: bool = false
@export var has_poi: bool = false
