extends Node
class_name EnemySpawner

signal enemy_destroyed(enemy: EnemyShip)
signal wave_spawned

const ENEMY_SCENE: PackedScene = preload("res://world/enemies/enemy_ship.tscn")

@export var spawn_interval_base: float = 4.5
@export var spawn_interval_activity_scale: float = 0.08
@export var spawn_interval_min: float = 0.8
@export var activity_per_extra_slot: float = 18.0
@export var live_cap_max: int = 8
@export var activity_per_wave_size: float = 28.0
@export var wave_size_max: int = 3
@export var spawn_distance_min: float = 24.0
@export var spawn_distance_max: float = 34.0

var enemies_remaining: int = 0
var spawn_cap_base: int = 2
var spawning_active: bool = false

var actor_layer: Node3D = null
var projectile_layer: Node3D = null
var player: PlayerShip = null
var spawn_center: Vector3 = Vector3.ZERO
var activity_tracker: ActivityTracker = null

var _spawn_timer: Timer

func _ready() -> void:
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_attempt_spawn)
	add_child(_spawn_timer)

func start_spawning() -> void:
	spawning_active = true
	_spawn_timer.start(3.5)

func stop_spawning() -> void:
	spawning_active = false
	_spawn_timer.stop()

func reset(cap: int) -> void:
	enemies_remaining = 0
	spawn_cap_base = cap
	spawning_active = false
	_spawn_timer.stop()

func _attempt_spawn() -> void:
	if not spawning_active:
		return
	var current_activity: float = activity_tracker.activity if activity_tracker else 0.0
	var live_cap: int = mini(spawn_cap_base + int(floor(current_activity / activity_per_extra_slot)), live_cap_max)
	if enemies_remaining >= live_cap:
		return
	_spawn_wave()
	var next_interval: float = maxf(spawn_interval_min, spawn_interval_base - (current_activity * spawn_interval_activity_scale))
	_spawn_timer.start(randf_range(next_interval * 0.8, next_interval * 1.2))

func _spawn_wave() -> void:
	if actor_layer == null or projectile_layer == null:
		return
	var current_activity: float = activity_tracker.activity if activity_tracker else 0.0
	var wave_size: int = mini(1 + int(floor(current_activity / activity_per_wave_size)), wave_size_max)
	for _index in range(wave_size):
		var enemy: EnemyShip = ENEMY_SCENE.instantiate() as EnemyShip
		var angle: float = randf() * TAU
		var distance: float = randf_range(spawn_distance_min, spawn_distance_max)
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
	if spawning_active and _spawn_timer.is_stopped():
		_attempt_spawn()
