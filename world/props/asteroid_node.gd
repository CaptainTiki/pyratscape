extends StaticBody3D
class_name AsteroidNode

signal mined_out

const PICKUP_SCENE: PackedScene = preload("res://world/props/resource_pickup.tscn")

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
	for _index in range(scrap_yield / 3):
		var pickup: ResourcePickup = PICKUP_SCENE.instantiate() as ResourcePickup
		pickup.global_position = global_position + Vector3(randf_range(-1.0, 1.0), 0.8, randf_range(-1.0, 1.0))
		pickup.pickup_type = ResourcePickup.PickupType.SCRAP
		pickup.amount = 3
		if world != null:
			world.register_pickup(pickup)
	for _index in range(crystal_yield):
		var crystal: ResourcePickup = PICKUP_SCENE.instantiate() as ResourcePickup
		crystal.global_position = global_position + Vector3(randf_range(-0.8, 0.8), 0.8, randf_range(-0.8, 0.8))
		crystal.pickup_type = ResourcePickup.PickupType.CRYSTAL
		crystal.amount = 1
		if world != null:
			world.register_pickup(crystal)
