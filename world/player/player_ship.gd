extends CharacterBody3D
class_name PlayerShip

const PROJECTILE_SCENE: PackedScene = preload("res://world/combat/projectile.tscn")

@export var base_move_speed: float = 28.0
@export var acceleration_rate: float = 34.0
@export var friction_rate: float = 22.0
@export var turn_speed: float = 3.8
@export var reverse_speed_multiplier: float = 0.55
@export var boost_multiplier: float = 1.7
@export var boost_duration: float = 0.4
@export var double_tap_window: float = 0.3
@export var max_hull: int = 100
@export var fire_cooldown: float = 0.22
@export var secondary_cooldown: float = 0.6
@export var projectile_damage: float = 12.0
@export var mining_damage: float = 18.0
@export var tractor_range: float = 7.5

var world: WorldRoot = null
var projectile_parent: Node3D = null
var fire_timer: float = 0.0
var secondary_fire_timer: float = 0.0
var hull: int = 100
var current_speed: float = 0.0
var boost_timer: float = 0.0
var forward_tap_timer: float = 0.0
var tractor_active: bool = false

@onready var muzzle_left: Node3D = $MuzzleLeft
@onready var muzzle_right: Node3D = $MuzzleRight
@onready var missile_muzzle: Node3D = $MissileMuzzle
@onready var tractor_area: Area3D = $TractorArea
@onready var tractor_visual: Node3D = $TractorVisual

func _ready() -> void:
	_sync_from_game_data()
	tractor_visual.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		if forward_tap_timer > 0.0:
			boost_timer = boost_duration
		forward_tap_timer = double_tap_window

func _physics_process(delta: float) -> void:
	if not visible:
		return
	fire_timer = maxf(0.0, fire_timer - delta)
	secondary_fire_timer = maxf(0.0, secondary_fire_timer - delta)
	boost_timer = maxf(0.0, boost_timer - delta)
	forward_tap_timer = maxf(0.0, forward_tap_timer - delta)
	_handle_movement(delta)
	_handle_fire()
	_handle_secondary_fire()
	_handle_tractor(delta)
	if Input.is_action_just_pressed("interact") and world != null:
		world.try_interact_at_station()

func _handle_movement(delta: float) -> void:
	var turn_input: float = 0.0
	if Input.is_action_pressed("move_left"):
		turn_input += 1.0
	if Input.is_action_pressed("move_right"):
		turn_input -= 1.0
	rotate_y(turn_input * turn_speed * delta)

	var throttle_input: float = 0.0
	if Input.is_action_pressed("move_up"):
		throttle_input += 1.0
	if Input.is_action_pressed("move_down"):
		throttle_input -= 1.0

	var top_speed: float = base_move_speed
	if boost_timer > 0.0 and throttle_input > 0.0:
		top_speed *= boost_multiplier
	if throttle_input < 0.0:
		top_speed *= reverse_speed_multiplier

	if absf(throttle_input) > 0.01:
		current_speed = move_toward(current_speed, top_speed * throttle_input, acceleration_rate * delta)
	else:
		current_speed = move_toward(current_speed, 0.0, friction_rate * delta)

	velocity = -global_basis.z * current_speed
	move_and_slide()
	global_position.y = 1.25

func _handle_fire() -> void:
	if not Input.is_action_pressed("fire_primary"):
		return
	if fire_timer > 0.0:
		return
	if projectile_parent == null:
		return
	fire_timer = fire_cooldown
	_spawn_projectile(muzzle_left.global_position, -global_basis.z, projectile_damage, false, 48.0, 0.2)
	_spawn_projectile(muzzle_right.global_position, -global_basis.z, projectile_damage, false, 48.0, 0.2)

func _handle_secondary_fire() -> void:
	if not Input.is_action_pressed("fire_secondary"):
		return
	if secondary_fire_timer > 0.0:
		return
	if projectile_parent == null:
		return
	secondary_fire_timer = secondary_cooldown
	_spawn_projectile(missile_muzzle.global_position, -global_basis.z, mining_damage, true, 26.0, 0.4)

func _spawn_projectile(spawn_position: Vector3, shot_direction: Vector3, damage_amount: float, mining_shot: bool, projectile_speed: float, projectile_scale: float) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	projectile.global_position = spawn_position
	projectile.direction = shot_direction
	projectile.damage = damage_amount
	projectile.is_mining = mining_shot
	projectile.source = self
	projectile.speed = projectile_speed
	projectile.scale = Vector3.ONE * projectile_scale
	projectile_parent.add_child(projectile)

func _handle_tractor(_delta: float) -> void:
	tractor_active = Input.is_action_pressed("fire_tractor")
	tractor_visual.visible = false
	if not tractor_active:
		return
	var overlapping_areas: Array[Area3D] = tractor_area.get_overlapping_areas()
	var closest_pickup: ResourcePickup = null
	var closest_distance: float = INF
	for area in overlapping_areas:
		if area is ResourcePickup:
			var pickup: ResourcePickup = area as ResourcePickup
			pickup.magnet_to(self)
			var distance: float = global_position.distance_to(pickup.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_pickup = pickup
	if closest_pickup != null:
		_update_tractor_visual(closest_pickup.global_position)

func _update_tractor_visual(target_position: Vector3) -> void:
	tractor_visual.visible = true
	var from_point: Vector3 = global_position
	var to_point: Vector3 = target_position
	var midpoint: Vector3 = (from_point + to_point) * 0.5
	tractor_visual.global_position = midpoint
	tractor_visual.look_at(to_point, Vector3.UP)
	var beam_length: float = from_point.distance_to(to_point)
	tractor_visual.scale = Vector3(1.0, 1.0, beam_length)

func is_tractor_active() -> bool:
	return tractor_active

func apply_damage(amount: int) -> void:
	hull = maxi(0, hull - amount)
	if GameData.instance != null:
		GameData.instance.player_hull = hull
	if hull <= 0:
		if world != null:
			world.mission_message = "Your ship was destroyed. Return with Esc and try again."
			world.world_state_changed.emit()
		queue_free()

func _sync_from_game_data() -> void:
	if GameData.instance == null:
		return
	base_move_speed = GameData.instance.player_move_speed
	boost_multiplier = GameData.instance.player_boost_multiplier
	max_hull = GameData.instance.player_max_hull
	hull = GameData.instance.player_hull
	fire_cooldown = GameData.instance.player_fire_rate
	projectile_damage = GameData.instance.player_damage
	mining_damage = GameData.instance.player_mining_damage
	tractor_range = GameData.instance.player_tractor_range
	var shape: CollisionShape3D = tractor_area.get_node("CollisionShape3D") as CollisionShape3D
	var sphere: SphereShape3D = shape.shape as SphereShape3D
	sphere.radius = tractor_range
