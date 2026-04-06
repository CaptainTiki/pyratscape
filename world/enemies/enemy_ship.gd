extends ShipEntity
class_name EnemyShip

signal destroyed(enemy: EnemyShip)

const PROJECTILE_SCENE: PackedScene = preload("res://world/combat/projectile.tscn")

@export_group("Movement")
@export var move_speed: float = 10.0
@export var turn_speed: float = 3.0
@export var preferred_range: float = 12.0
@export var preferred_range_variance: float = 2.0

@export_group("Combat")
@export var fire_cooldown: float = 1.4
@export var projectile_damage: float = 5.0
@export var engage_range: float = 18.0

@export_group("Engagement")
@export var engage_delay_min: float = 0.5
@export var engage_delay_max: float = 1.5

var target: PlayerShip = null
var _engage_delay: float = 0.0
var _body_material: StandardMaterial3D = null
var _base_color: Color = Color(0.95, 0.33, 0.25, 1.0)

@onready var muzzle: Node3D = $Muzzle
@onready var _body_mesh: MeshInstance3D = $Body
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
	preferred_range += randf_range(-preferred_range_variance, preferred_range_variance)
	_engage_delay = randf_range(engage_delay_min, engage_delay_max)
	_body_material = _body_mesh.material_override.duplicate() as StandardMaterial3D
	_body_mesh.material_override = _body_material
	_health.damaged.connect(_on_damaged)

func _physics_process(delta: float) -> void:
	var world: WorldRoot = get_tree().get_first_node_in_group("world_root") as WorldRoot
	if target == null or not is_instance_valid(target):
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if _engage_delay > 0.0:
		_engage_delay -= delta
		velocity = Vector3.ZERO
		move_and_slide()
		global_position.y = 1.25
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
		basis = basis.slerp(Basis.looking_at(to_target.normalized(), Vector3.UP), turn_speed * delta)
	move_and_slide()
	global_position.y = 1.25
	_collision_handler.tick(self, delta)
	if world != null:
		var station_distance: float = global_position.distance_to(world.station_anchor.global_position)
		if station_distance <= 6.0 and _station_attack_timer.is_stopped():
			world.sector_controller.apply_station_damage(6)
			_station_attack_timer.start(1.2)
	if distance <= engage_range:
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

func _on_damaged() -> void:
	if _body_material == null:
		return
	_body_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(_body_material, "albedo_color", _base_color, 0.15)

func _on_health_depleted() -> void:
	_spawn_explosion()
	_spawn_pickups()
	destroyed.emit(self)
	queue_free()

func _spawn_explosion() -> void:
	var sphere := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.6
	mesh.height = 1.2
	sphere.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.1, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material_override = mat
	sphere.global_position = global_position
	get_tree().root.add_child(sphere)
	var tween := sphere.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sphere, "scale", Vector3(4.0, 4.0, 4.0), 0.35)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tween.set_parallel(false)
	tween.tween_callback(sphere.queue_free)

func _spawn_pickups() -> void:
	var world: WorldRoot = get_tree().get_first_node_in_group("world_root") as WorldRoot
	PickupSpawner.spawn(world, global_position, 6, 1 if randi() % 3 == 0 else 0)
