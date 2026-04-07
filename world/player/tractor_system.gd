extends Node
class_name TractorSystem

enum TractorState { IDLE, CHARGING, LOCKED }

@export var tractor_range: float = 7.5
@export var cone_half_angle_deg: float = 40.0
@export var lock_on_time: float = 1.5
@export var asteroid_pull_strength: float = 4.0

var ship: Node3D = null
var tractor_area: Area3D = null
var tractor_visual: Node3D = null

var tractor_active: bool = false  # true when LOCKED (used by ResourcePickup body_entered)
var _state: TractorState = TractorState.IDLE
var _lock_timer: float = 0.0
var _locked_target: Node3D = null
var _beam_material: StandardMaterial3D = null

func initialize() -> void:
	var beam: MeshInstance3D = tractor_visual.get_node("Beam") as MeshInstance3D
	_beam_material = beam.material_override.duplicate() as StandardMaterial3D
	beam.material_override = _beam_material
	tractor_visual.visible = false

func tick(delta: float) -> void:
	tractor_active = false
	if not Input.is_action_pressed("fire_tractor"):
		_reset()
		return

	var target: Node3D = _find_cone_target()

	match _state:
		TractorState.IDLE:
			if target == null:
				tractor_visual.visible = false
				return
			_locked_target = target
			_state = TractorState.CHARGING
			_lock_timer = 0.0

		TractorState.CHARGING:
			if target == null or target != _locked_target:
				_reset()
				return
			_lock_timer += delta
			_show_charging(_locked_target.global_position)
			if _lock_timer >= lock_on_time:
				_state = TractorState.LOCKED

		TractorState.LOCKED:
			if not is_instance_valid(_locked_target):
				_reset()
				return
			tractor_active = true
			_apply_locked(delta)
			_show_locked(_locked_target.global_position)

func set_range(range_value: float) -> void:
	tractor_range = range_value
	var shape: CollisionShape3D = tractor_area.get_node("CollisionShape3D") as CollisionShape3D
	var sphere: SphereShape3D = shape.shape as SphereShape3D
	sphere.radius = tractor_range

func _reset() -> void:
	_state = TractorState.IDLE
	_lock_timer = 0.0
	_locked_target = null
	tractor_visual.visible = false

func _find_cone_target() -> Node3D:
	var forward: Vector3 = -ship.global_basis.z
	var cos_threshold: float = cos(deg_to_rad(cone_half_angle_deg))
	var best: Node3D = null
	var best_dist: float = INF

	for area in tractor_area.get_overlapping_areas():
		if area is ResourcePickup:
			var dir: Vector3 = (area.global_position - ship.global_position).normalized()
			if forward.dot(dir) >= cos_threshold:
				var dist: float = ship.global_position.distance_to(area.global_position)
				if dist < best_dist:
					best_dist = dist
					best = area

	for body in tractor_area.get_overlapping_bodies():
		if body is AsteroidNode:
			var dir: Vector3 = (body.global_position - ship.global_position).normalized()
			if forward.dot(dir) >= cos_threshold:
				var dist: float = ship.global_position.distance_to(body.global_position)
				if dist < best_dist:
					best_dist = dist
					best = body

	return best

func _apply_locked(delta: float) -> void:
	if _locked_target is ResourcePickup:
		(_locked_target as ResourcePickup).magnet_to(ship)
	elif _locked_target is AsteroidNode:
		(_locked_target as AsteroidNode).apply_tractor_drag(ship.global_position, asteroid_pull_strength, delta)

func _show_charging(target_pos: Vector3) -> void:
	var t: float = _lock_timer / lock_on_time
	_beam_material.albedo_color = Color(0.35, 0.95, 1.0, lerp(0.05, 0.35, t))
	_update_beam_transform(target_pos)
	tractor_visual.visible = true

func _show_locked(target_pos: Vector3) -> void:
	_beam_material.albedo_color = Color(0.35, 0.95, 1.0, 0.45)
	_update_beam_transform(target_pos)
	tractor_visual.visible = true

func _update_beam_transform(target_pos: Vector3) -> void:
	var from_point: Vector3 = ship.global_position
	tractor_visual.global_position = (from_point + target_pos) * 0.5
	tractor_visual.look_at(target_pos, Vector3.UP)
	tractor_visual.scale = Vector3(1.0, 1.0, from_point.distance_to(target_pos))
