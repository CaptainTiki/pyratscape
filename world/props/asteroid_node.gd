extends StaticBody3D
class_name AsteroidNode

signal mined_out

@export var max_integrity: float = 42.0
@export var scrap_yield: int = 12
@export var crystal_yield: int = 2

var integrity: float = 42.0

func _ready() -> void:
	integrity = max_integrity

func apply_damage(amount: float) -> void:
	integrity = maxf(0.0, integrity - amount)
	if integrity <= 0.0:
		_spawn_pickups()
		mined_out.emit()
		queue_free()

func apply_collision_damage(amount: int) -> void:
	apply_damage(float(amount))

func apply_mining_damage(amount: float) -> void:
	apply_damage(amount)

func _spawn_pickups() -> void:
	var world: WorldRoot = get_tree().get_first_node_in_group("world_root") as WorldRoot
	PickupSpawner.spawn(world, global_position, scrap_yield, crystal_yield)
