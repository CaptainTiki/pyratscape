extends ShipEntity
class_name EnemyShip

signal destroyed(enemy: EnemyShip)

const PROJECTILE_SCENE: PackedScene = preload("res://world/combat/projectile.tscn")

@export var move_speed: float = 13.0
@export var fire_cooldown: float = 1.0
@export var projectile_damage: float = 8.0
@export var preferred_range: float = 12.0

var target: PlayerShip = null

@onready var muzzle: Node3D = $Muzzle
@onready var _health: HealthComponent = $HealthComponent
@onready var _collision_handler: CollisionDamageHandler = $CollisionDamageHandler

var _fire_timer: Timer
var _station_attack_timer: Timer

func _ready() -> void:
	health = _health
	health.destroyed.connect(_on_health_depleted)
	_collision_handler.collision_hit.connect(_on_collision_hit)
	_fire_timer = Timer.new()
	_fire_timer.one_shot = true
	add_child(_fire_timer)
	_fire_timer.start(0.4)
	_station_attack_timer = Timer.new()
	_station_attack_timer.one_shot = true
	add_child(_station_attack_timer)
	_station_attack_timer.start(1.2)

func _physics_process(delta: float) -> void:
	var world: WorldRoot = get_tree().get_first_node_in_group("world_root") as WorldRoot
	if target == null or not is_instance_valid(target):
		velocity = Vector3.ZERO
		move_and_slide()
		return
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
	_collision_handler.tick(self, delta)
	if world != null:
		var station_distance: float = global_position.distance_to(world.station_anchor.global_position)
		if station_distance <= 6.0 and _station_attack_timer.is_stopped():
			world.sector_controller.apply_station_damage(6)
			_station_attack_timer.start(1.2)
	if distance <= 18.0:
		_try_fire()

func _on_collision_hit(damage: int) -> void:
	apply_damage(damage)

func _try_fire() -> void:
	if not _fire_timer.is_stopped():
		return
	if projectile_parent == null:
		return
	_fire_timer.start(fire_cooldown)
	var projectile: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	projectile.global_position = muzzle.global_position
	projectile.direction = (target.global_position - global_position).normalized()
	projectile.damage = projectile_damage
	projectile.source = self
	projectile_parent.add_child(projectile)

func _on_health_depleted() -> void:
	_spawn_pickups()
	destroyed.emit(self)
	queue_free()

func _spawn_pickups() -> void:
	var world: WorldRoot = get_tree().get_first_node_in_group("world_root") as WorldRoot
	PickupSpawner.spawn(world, global_position, 6, 1 if randi() % 3 == 0 else 0)
