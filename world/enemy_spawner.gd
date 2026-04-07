extends Node
class_name EnemySpawner

signal enemy_destroyed(enemy: EnemyShip)
signal wave_spawned

const ENEMY_SCENE: PackedScene = preload("res://world/enemies/enemy_ship.tscn")

@export_group("Spawn Position")
@export var spawn_distance_min: float = 24.0
@export var spawn_distance_max: float = 34.0

var enemies_remaining: int = 0
var spawning_active: bool = false

var actor_layer: Node3D = null
var projectile_layer: Node3D = null
var player: PlayerShip = null
var spawn_center: Vector3 = Vector3.ZERO
var activity_tracker: ActivityTracker = null
var world_simulation: WorldSimulation = null
var enemy_forces: EnemyForces = null
var current_sector_id: int = 0

var _spawned_enemies: Array[EnemyShip] = []
var _update_timer: float = 0.0
var _update_interval: float = 0.5  # Check enemy count every 0.5s

func _ready() -> void:
	pass

func start_spawning() -> void:
	spawning_active = true

func stop_spawning() -> void:
	spawning_active = false

func reset(cap: int) -> void:
	enemies_remaining = 0
	spawning_active = false
	# Note: cap parameter kept for compatibility but not used in simulation mode

func _process(delta: float) -> void:
	if not spawning_active or enemy_forces == null or world_simulation == null:
		return

	_update_timer += delta
	if _update_timer >= _update_interval:
		_update_timer = 0.0
		_sync_enemies_with_simulation()

func _sync_enemies_with_simulation() -> void:
	# Get the target enemy count from the simulation
	var target_count = enemy_forces.get_enemies_in_sector(current_sector_id)

	# Remove dead enemies from our list
	_spawned_enemies = _spawned_enemies.filter(func(e): return is_instance_valid(e))

	var current_count = _spawned_enemies.size()

	# Spawn new enemies if we need more
	while current_count < target_count:
		_spawn_single_enemy()
		current_count += 1

	# Despawn excess enemies if we have too many
	while current_count > target_count and _spawned_enemies.size() > 0:
		var enemy = _spawned_enemies.pop_back()
		if is_instance_valid(enemy):
			enemy.queue_free()
		current_count -= 1

	enemies_remaining = current_count

func _spawn_single_enemy() -> void:
	if actor_layer == null or projectile_layer == null:
		return

	var enemy: EnemyShip = ENEMY_SCENE.instantiate() as EnemyShip
	var angle: float = randf() * TAU
	var distance: float = randf_range(spawn_distance_min, spawn_distance_max)
	var spawn_position: Vector3 = spawn_center + Vector3(cos(angle) * distance, 1.25, sin(angle) * distance)
	enemy.global_position = spawn_position
	enemy.target = player
	enemy.projectile_parent = projectile_layer
	enemy.destroyed.connect(_on_enemy_destroyed)
	actor_layer.add_child(enemy)
	_spawned_enemies.append(enemy)

func _on_enemy_destroyed(enemy: EnemyShip) -> void:
	_spawned_enemies.erase(enemy)
	enemies_remaining = maxi(0, enemies_remaining - 1)
	enemy_destroyed.emit(enemy)

	# Update enemy forces
	if enemy_forces != null:
		enemy_forces.remove_enemy_from_sector(current_sector_id, "fighter")
