extends Node
class_name EnemySpawner

signal enemy_destroyed(enemy: EnemyShip)
signal wave_spawned

const ENEMY_SCENE: PackedScene = preload("res://world/enemies/enemy_ship.tscn")

var enemies_remaining: int = 0
var spawn_timer: float = 20.0
var spawn_cap_base: int = 2
var spawning_active: bool = false

var actor_layer: Node3D = null
var projectile_layer: Node3D = null
var player: PlayerShip = null
var spawn_center: Vector3 = Vector3.ZERO
var activity_tracker: ActivityTracker = null

func _process(delta: float) -> void:
	if not spawning_active:
		return
	spawn_timer -= delta
	var current_activity: float = activity_tracker.activity if activity_tracker else 0.0
	var live_cap: int = spawn_cap_base + int(floor(current_activity / 18.0))
	live_cap = mini(live_cap, 8)
	if spawn_timer > 0.0 or enemies_remaining >= live_cap:
		return
	_spawn_wave()
	var next_interval: float = maxf(0.8, 4.5 - (current_activity * 0.08))
	spawn_timer = randf_range(next_interval * 0.8, next_interval * 1.2)

func start_spawning() -> void:
	spawning_active = true

func stop_spawning() -> void:
	spawning_active = false

func reset(cap: int) -> void:
	enemies_remaining = 0
	spawn_timer = 3.5
	spawn_cap_base = cap
	spawning_active = false

func _spawn_wave() -> void:
	if actor_layer == null or projectile_layer == null:
		return
	var current_activity: float = activity_tracker.activity if activity_tracker else 0.0
	var wave_size: int = 1 + int(floor(current_activity / 28.0))
	wave_size = mini(wave_size, 3)
	for _index in range(wave_size):
		var enemy: EnemyShip = ENEMY_SCENE.instantiate() as EnemyShip
		var angle: float = randf() * TAU
		var distance: float = randf_range(24.0, 34.0)
		var spawn_position: Vector3 = spawn_center + Vector3(cos(angle) * distance, 1.25, sin(angle) * distance)
		enemy.global_position = spawn_position
		enemy.target = player
		enemy.projectile_parent = projectile_layer
		enemy.destroyed.connect(_on_enemy_destroyed)
		actor_layer.add_child(enemy)
		enemies_remaining += 1
	wave_spawned.emit()

func _on_enemy_destroyed(enemy: EnemyShip) -> void:
	enemies_remaining = maxi(0, enemies_remaining - 1)
	enemy_destroyed.emit(enemy)
