extends Node
class_name StationManager

signal deploy_finished
signal inbound_finished
signal dock_finished
signal redeploy_finished

enum TransitionType { NONE, DEPLOYING, INBOUND, DOCKING, REDEPLOYING }

var station_anchor: StaticBody3D = null
var station_area: Area3D = null
var station_present: bool = false
var depart_tween: Tween = null

var transition_type: TransitionType = TransitionType.NONE
var transition_timer: float = 0.0
var transition_duration: float = 1.2

func _process(delta: float) -> void:
	if transition_type == TransitionType.NONE:
		return
	_update_transition(delta)

func begin_deploy() -> void:
	station_present = true
	_set_visible(true)
	station_anchor.scale = Vector3.ONE * 0.01
	station_area.monitoring = false
	transition_type = TransitionType.DEPLOYING
	transition_timer = 0.0

func begin_inbound() -> void:
	if depart_tween != null:
		depart_tween.kill()
	station_present = true
	_set_visible(true)
	station_anchor.scale = Vector3.ONE * 0.01
	station_area.monitoring = false
	transition_type = TransitionType.INBOUND
	transition_timer = 0.0

func begin_dock() -> void:
	transition_type = TransitionType.DOCKING
	transition_timer = 0.0

func depart_after_launch() -> void:
	station_present = false
	station_area.monitoring = false
	station_anchor.set_collision_layer_value(1, false)
	if depart_tween != null:
		depart_tween.kill()
	depart_tween = create_tween()
	depart_tween.tween_property(station_anchor, "scale", Vector3.ONE * 0.01, 0.9)
	depart_tween.tween_callback(func(): _set_visible(false))

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

func _update_transition(delta: float) -> void:
	transition_timer += delta
	var t: float = clampf(transition_timer / transition_duration, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - t, 3.0)
	if transition_type == TransitionType.DOCKING:
		station_anchor.scale = Vector3.ONE * maxf(0.01, 1.0 - eased)
	else:
		station_anchor.scale = Vector3.ONE * maxf(0.01, eased)
	if t < 1.0:
		return
	match transition_type:
		TransitionType.DEPLOYING:
			station_anchor.scale = Vector3.ONE
			station_area.monitoring = true
			transition_type = TransitionType.NONE
			deploy_finished.emit()
		TransitionType.INBOUND:
			station_anchor.scale = Vector3.ONE
			station_area.monitoring = true
			transition_type = TransitionType.NONE
			inbound_finished.emit()
		TransitionType.DOCKING:
			station_anchor.scale = Vector3.ONE * 0.01
			_set_visible(false)
			station_area.monitoring = false
			station_present = false
			transition_type = TransitionType.NONE
			dock_finished.emit()
		TransitionType.REDEPLOYING:
			station_anchor.scale = Vector3.ONE
			station_area.monitoring = true
			transition_type = TransitionType.NONE
			redeploy_finished.emit()
