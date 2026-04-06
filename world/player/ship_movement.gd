extends Node
class_name ShipMovement

@export var base_move_speed: float = 28.0
@export var acceleration_rate: float = 34.0
@export var friction_rate: float = 22.0
@export var turn_speed: float = 3.8
@export var reverse_speed_multiplier: float = 0.55
@export var boost_multiplier: float = 1.7
@export var boost_duration: float = 0.4
@export var double_tap_window: float = 0.3
@export var collision_damage_scale: float = 0.42
@export var collision_damage_cooldown: float = 0.3

# Set by PlayerShip in _ready()
var ship: CharacterBody3D = null
var hull_component: HullComponent = null

var current_speed: float = 0.0
var boost_timer: float = 0.0
var forward_tap_timer: float = 0.0
var collision_damage_timer: float = 0.0

func handle_input_event(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		if forward_tap_timer > 0.0:
			boost_timer = boost_duration
		forward_tap_timer = double_tap_window

func tick(delta: float) -> void:
	boost_timer = maxf(0.0, boost_timer - delta)
	forward_tap_timer = maxf(0.0, forward_tap_timer - delta)
	collision_damage_timer = maxf(0.0, collision_damage_timer - delta)
	_handle_movement(delta)
	_handle_collisions()

func _handle_movement(delta: float) -> void:
	var turn_input: float = 0.0
	if Input.is_action_pressed("move_left"):
		turn_input += 1.0
	if Input.is_action_pressed("move_right"):
		turn_input -= 1.0
	ship.rotate_y(turn_input * turn_speed * delta)

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

	ship.velocity = -ship.global_basis.z * current_speed
	ship.move_and_slide()
	ship.global_position.y = 1.25

func _handle_collisions() -> void:
	if collision_damage_timer > 0.0:
		return
	var highest_impact: float = 0.0
	var impacted_bodies: Array[Node] = []
	for i in range(ship.get_slide_collision_count()):
		var collision: KinematicCollision3D = ship.get_slide_collision(i)
		var collider: Node = collision.get_collider() as Node
		if collider == null:
			continue
		var impact_speed: float = absf(current_speed)
		if impact_speed < 6.0:
			continue
		highest_impact = maxf(highest_impact, impact_speed)
		if not impacted_bodies.has(collider):
			impacted_bodies.append(collider)
	if highest_impact <= 0.0:
		return
	var collision_damage: int = maxi(1, int(round(highest_impact * collision_damage_scale)))
	hull_component.take_damage(collision_damage)
	for collider in impacted_bodies:
		if collider.has_method("apply_collision_damage"):
			collider.apply_collision_damage(collision_damage)
		elif collider.has_method("apply_damage") and collider != ship:
			collider.apply_damage(collision_damage)
	current_speed *= -0.35
	collision_damage_timer = collision_damage_cooldown
