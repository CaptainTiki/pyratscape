extends StaticBody3D
class_name AsteroidNode

enum AsteroidSize { LARGE, MEDIUM, SMALL }

signal mined_out
signal split(origin: Vector3, child_size: AsteroidSize, child_count: int)

@export var size: AsteroidSize = AsteroidSize.LARGE

var max_integrity: float = 0.0
var integrity: float = 0.0

func _ready() -> void:
	_configure_for_size()
	integrity = max_integrity

func _configure_for_size() -> void:
	match size:
		AsteroidSize.LARGE:
			max_integrity = 42.0
		AsteroidSize.MEDIUM:
			max_integrity = 20.0
			scale = Vector3(0.55, 0.55, 0.55)
		AsteroidSize.SMALL:
			max_integrity = 10.0
			scale = Vector3(0.3, 0.3, 0.3)

func apply_damage(amount: float) -> void:
	integrity = maxf(0.0, integrity - amount)
	if integrity <= 0.0:
		_on_destroyed()

func apply_collision_damage(amount: int) -> void:
	apply_damage(float(amount))

func apply_mining_damage(amount: float) -> void:
	apply_damage(amount)

func _on_destroyed() -> void:
	_spawn_drops()
	match size:
		AsteroidSize.LARGE:
			split.emit(global_position, AsteroidSize.MEDIUM, randi_range(2, 3))
		AsteroidSize.MEDIUM:
			split.emit(global_position, AsteroidSize.SMALL, randi_range(3, 4))
		AsteroidSize.SMALL:
			mined_out.emit()
	queue_free()

func apply_tractor_drag(toward: Vector3, strength: float, delta: float) -> void:
	var dir: Vector3 = toward - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		return
	global_position += dir.normalized() * strength * delta

func _spawn_drops() -> void:
	var world: WorldRoot = get_tree().get_first_node_in_group("world_root") as WorldRoot
	match size:
		AsteroidSize.LARGE, AsteroidSize.MEDIUM:
			PickupSpawner.spawn(world, global_position, randi_range(1, 2), 0)
		AsteroidSize.SMALL:
			PickupSpawner.spawn(world, global_position, randi_range(4, 5), randi_range(0, 2))
