extends Node
class_name StationManager

signal deploy_finished
signal inbound_finished
signal dock_finished
signal redeploy_finished
signal bay_opened
signal bay_closed

@export var bay_duration: float = 25.0
@export var bay_pull_strength: float = 6.0
@export var bay_pull_radius: float = 20.0

var station_anchor: StaticBody3D = null
var station_area: Area3D = null
var station_present: bool = false

var bay_open: bool = false
var _bay_timer: float = 0.0

var _active_tween: Tween = null

func _process(delta: float) -> void:
	if not bay_open:
		return
	_bay_timer -= delta
	if _bay_timer <= 0.0:
		_bay_timer = 0.0
		bay_open = false
		bay_closed.emit()

func begin_deploy() -> void:
	station_present = true
	_set_visible(true)
	station_anchor.scale = Vector3.ONE * 0.01
	station_area.monitoring = false
	_start_tween(Vector3.ONE, 1.2, func():
		station_area.monitoring = true
		deploy_finished.emit()
	)

func begin_inbound() -> void:
	station_present = true
	_set_visible(true)
	station_anchor.scale = Vector3.ONE * 0.01
	station_area.monitoring = false
	_start_tween(Vector3.ONE, 1.2, func():
		station_area.monitoring = true
		inbound_finished.emit()
	)

func begin_dock() -> void:
	close_bay()
	_start_tween(Vector3.ONE * 0.01, 1.2, func():
		_set_visible(false)
		station_area.monitoring = false
		station_present = false
		dock_finished.emit()
	)

func depart_after_launch() -> void:
	station_present = false
	station_area.monitoring = false
	station_anchor.set_collision_layer_value(1, false)
	_start_tween(Vector3.ONE * 0.01, 0.9, func(): _set_visible(false))

func open_bay() -> void:
	if not station_present:
		return
	bay_open = true
	_bay_timer = bay_duration
	bay_opened.emit()

func close_bay() -> void:
	if not bay_open:
		return
	bay_open = false
	_bay_timer = 0.0
	bay_closed.emit()

func get_bay_time_remaining() -> int:
	return ceili(_bay_timer)

func get_bay_pull_force(player_pos: Vector3) -> Vector3:
	if not bay_open or not station_present:
		return Vector3.ZERO
	var to_station: Vector3 = station_anchor.global_position - player_pos
	to_station.y = 0.0
	var dist: float = to_station.length()
	if dist < 1.0 or dist > bay_pull_radius:
		return Vector3.ZERO
	return to_station.normalized() * bay_pull_strength

func is_player_in_range(player: Node3D) -> bool:
	if not station_present or player == null or not is_instance_valid(player):
		return false
	var overlapping_bodies: Array[Node3D] = station_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body == player:
			return true
	return false

func apply_damage(amount: int) -> void:
	if not station_present:
		return
	if GameData.instance == null:
		return
	GameData.instance.station_integrity = maxi(0, GameData.instance.station_integrity - amount)

func _set_visible(show_station: bool) -> void:
	station_anchor.visible = show_station
	station_anchor.set_collision_layer_value(1, show_station)

func _start_tween(target_scale: Vector3, duration: float, on_done: Callable) -> void:
	if _active_tween != null:
		_active_tween.kill()
	_active_tween = create_tween()
	_active_tween.tween_property(station_anchor, "scale", target_scale, duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_active_tween.tween_callback(on_done)
