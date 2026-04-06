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

# Set by PlayerShip in _ready()
var ship: CharacterBody3D = null
var collision_handler: CollisionDamageHandler = null:
	set(value):
		collision_handler = value
		if collision_handler:
			collision_handler.collision_hit.connect(_on_collision_hit)

var current_speed: float = 0.0
var boost_timer: float = 0.0

var _double_tap_timer: Timer

func _ready() -> void:
	_double_tap_timer = Timer.new()
	_double_tap_timer.one_shot = true
	add_child(_double_tap_timer)

func handle_input_event(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		if not _double_tap_timer.is_stopped():
			boost_timer = boost_duration
		_double_tap_timer.start(double_tap_window)

func tick(delta: float) -> void:
	boost_timer = maxf(0.0, boost_timer - delta)
	_handle_movement(delta)
	if collision_handler:
		collision_handler.tick(ship, delta)

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

func _on_collision_hit(damage: int) -> void:
	current_speed *= -0.35
	ship.apply_damage(damage)
