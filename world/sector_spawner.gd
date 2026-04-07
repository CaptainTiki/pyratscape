extends Node
class_name SectorSpawner

const PLAYER_SCENE: PackedScene = preload("res://world/player/player_ship.tscn")
const ASTEROID_SCENE: PackedScene = preload("res://world/props/asteroid_node.tscn")

signal asteroid_mined_out
signal asteroid_split

var actor_layer: Node3D = null
var projectile_layer: Node3D = null
var pickup_layer: Node3D = null
var station_anchor: StaticBody3D = null
var camera_rig: CameraRig = null
var enemy_spawner: EnemySpawner = null
var world_root: WorldRoot = null

var player: PlayerShip = null
var asteroids_remaining: int = 0

func setup(world: WorldRoot) -> void:
	world_root = world
	actor_layer = world.actor_layer
	projectile_layer = world.projectile_layer
	pickup_layer = world.pickup_layer
	station_anchor = world.station_anchor
	camera_rig = world.camera_rig
	enemy_spawner = world.enemy_spawner

func clear() -> void:
	for child in actor_layer.get_children():
		child.queue_free()
	for child in projectile_layer.get_children():
		child.queue_free()
	for child in pickup_layer.get_children():
		child.queue_free()
	player = null
	camera_rig.player = null
	enemy_spawner.player = null

func spawn_player() -> void:
	if GameData.instance != null:
		GameData.instance.restore_ship_hull()
	player = PLAYER_SCENE.instantiate() as PlayerShip
	player.global_position = station_anchor.global_position + Vector3(0.0, 0.25, 8.0)
	player.projectile_parent = projectile_layer
	player.world = world_root
	actor_layer.add_child(player)
	camera_rig.player = player
	enemy_spawner.player = player
	enemy_spawner.spawn_center = station_anchor.global_position

func spawn_asteroids(count: int) -> void:
	asteroids_remaining = 0
	var min_distance: float = 6.0
	var placed: Array[Vector3] = []
	for _i in range(count):
		var spawn_position: Vector3 = Vector3.ZERO
		for _attempt in range(20):
			var angle: float = randf() * TAU
			var distance: float = randf_range(10.0, 28.0)
			spawn_position = Vector3(cos(angle) * distance, 1.0, sin(angle) * distance)
			var too_close: bool = false
			for existing in placed:
				if spawn_position.distance_to(existing) < min_distance:
					too_close = true
					break
			if not too_close:
				break
		placed.append(spawn_position)
		var asteroid: AsteroidNode = ASTEROID_SCENE.instantiate() as AsteroidNode
		asteroid.global_position = spawn_position
		asteroid.mined_out.connect(_on_asteroid_mined_out)
		asteroid.split.connect(_on_asteroid_split)
		actor_layer.add_child(asteroid)
		asteroids_remaining += 1

func register_pickup(pickup: ResourcePickup) -> void:
	pickup_layer.add_child(pickup)

func _on_asteroid_mined_out() -> void:
	asteroids_remaining = maxi(0, asteroids_remaining - 1)
	asteroid_mined_out.emit()

func _on_asteroid_split(origin: Vector3, child_size: AsteroidNode.AsteroidSize, child_count: int) -> void:
	asteroids_remaining = maxi(0, asteroids_remaining - 1)
	for i in range(child_count):
		var offset := Vector3(randf_range(-2.5, 2.5), 0.0, randf_range(-2.5, 2.5))
		var child: AsteroidNode = ASTEROID_SCENE.instantiate() as AsteroidNode
		child.size = child_size
		child.global_position = origin + offset
		child.mined_out.connect(_on_asteroid_mined_out)
		child.split.connect(_on_asteroid_split)
		actor_layer.add_child(child)
		asteroids_remaining += 1
	asteroid_split.emit()
