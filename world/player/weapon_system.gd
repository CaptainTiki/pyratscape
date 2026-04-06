extends Node
class_name WeaponSystem

const PROJECTILE_SCENE: PackedScene = preload("res://world/combat/projectile.tscn")

@export var fire_cooldown: float = 0.22
@export var secondary_cooldown: float = 0.6
@export var projectile_damage: float = 12.0
@export var missile_damage: float = 18.0

# Set by PlayerShip in _ready() and via setters
var source: Node3D = null
var projectile_parent: Node3D = null
var muzzle_left: Node3D = null
var muzzle_right: Node3D = null
var missile_muzzle: Node3D = null

var _fire_timer: Timer
var _secondary_timer: Timer

func _ready() -> void:
	_fire_timer = Timer.new()
	_fire_timer.one_shot = true
	add_child(_fire_timer)
	_secondary_timer = Timer.new()
	_secondary_timer.one_shot = true
	add_child(_secondary_timer)

func tick(_delta: float) -> void:
	_handle_fire()
	_handle_secondary_fire()

func _handle_fire() -> void:
	if not Input.is_action_pressed("fire_primary"):
		return
	if not _fire_timer.is_stopped() or projectile_parent == null:
		return

	_fire_timer.start(fire_cooldown)
	_spawn_projectile(muzzle_left.global_position, -source.global_basis.z, projectile_damage, 48.0, 0.2)
	_spawn_projectile(muzzle_right.global_position, -source.global_basis.z, projectile_damage, 48.0, 0.2)

func _handle_secondary_fire() -> void:
	if not Input.is_action_pressed("fire_secondary"):
		return
	if not _secondary_timer.is_stopped() or projectile_parent == null:
		return
	_secondary_timer.start(secondary_cooldown)
	_spawn_projectile(missile_muzzle.global_position, -source.global_basis.z, missile_damage, 26.0, 0.4)

func _spawn_projectile(spawn_position: Vector3, shot_direction: Vector3, damage: float, speed: float, proj_scale: float) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	projectile.global_position = spawn_position
	projectile.direction = shot_direction
	projectile.damage = damage
	projectile.source = source
	projectile.speed = speed
	projectile.scale = Vector3.ONE * proj_scale
	projectile_parent.add_child(projectile)
