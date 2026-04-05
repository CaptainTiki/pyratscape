extends CharacterBody3D
class_name EnemyShip

signal destroyed(enemy: EnemyShip)

const PROJECTILE_SCENE: PackedScene = preload("res://world/combat/projectile.tscn")
const PICKUP_SCENE: PackedScene = preload("res://world/props/resource_pickup.tscn")

@export var max_hull: int = 34
@export var move_speed: float = 13.0
@export var fire_cooldown: float = 1.0
@export var projectile_damage: float = 8.0
@export var preferred_range: float = 12.0

var target: PlayerShip = null
var projectile_parent: Node3D = null
var hull: int = 34
var fire_timer: float = 0.4
var station_attack_timer: float = 1.2

@onready var muzzle: Node3D = $Muzzle

func _ready() -> void:
	hull = max_hull

func _physics_process(delta: float) -> void:
	var world: WorldRoot = get_tree().get_first_node_in_group("world_root") as WorldRoot
	if target == null or not is_instance_valid(target):
		velocity = Vector3.ZERO
		move_and_slide()
		return
	fire_timer = maxf(0.0, fire_timer - delta)
	station_attack_timer = maxf(0.0, station_attack_timer - delta)
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	var move_direction: Vector3 = Vector3.ZERO
	if distance > preferred_range:
		move_direction = to_target.normalized()
	elif distance < preferred_range * 0.65:
		move_direction = -to_target.normalized()
	velocity = move_direction * move_speed
	if to_target.length() > 0.01:
		basis = basis.slerp(Basis.looking_at(to_target.normalized(), Vector3.UP), 6.0 * delta)
	move_and_slide()
	global_position.y = 1.25
	if world != null:
		var station_distance: float = global_position.distance_to(world.station_anchor.global_position)
		if station_distance <= 6.0 and station_attack_timer <= 0.0:
			world.apply_station_damage(6)
			station_attack_timer = 1.2
	if distance <= 18.0:
		_try_fire()

func _try_fire() -> void:
	if fire_timer > 0.0:
		return
	if projectile_parent == null:
		return
	fire_timer = fire_cooldown
	var projectile: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	projectile.global_position = muzzle.global_position
	projectile.direction = (target.global_position - global_position).normalized()
	projectile.damage = projectile_damage
	projectile.source = self
	projectile_parent.add_child(projectile)

func apply_damage(amount: int) -> void:
	hull = maxi(0, hull - amount)
	if hull <= 0:
		_spawn_pickups()
		destroyed.emit(self)
		queue_free()

func _spawn_pickups() -> void:
	var world: WorldRoot = get_tree().get_first_node_in_group("world_root") as WorldRoot
	var scrap_pickup: ResourcePickup = PICKUP_SCENE.instantiate() as ResourcePickup
	scrap_pickup.global_position = global_position + Vector3(0.8, 0.0, 0.0)
	scrap_pickup.pickup_type = ResourcePickup.PickupType.SCRAP
	scrap_pickup.amount = 6
	if world != null:
		world.register_pickup(scrap_pickup)
	if randi() % 3 == 0:
		var crystal_pickup: ResourcePickup = PICKUP_SCENE.instantiate() as ResourcePickup
		crystal_pickup.global_position = global_position + Vector3(-0.8, 0.0, 0.0)
		crystal_pickup.pickup_type = ResourcePickup.PickupType.CRYSTAL
		crystal_pickup.amount = 1
		if world != null:
			world.register_pickup(crystal_pickup)
