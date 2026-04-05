extends Node3D
class_name CameraRig

var player: Node3D = null
var follow_target: Node3D = null
var offset: Vector3 = Vector3(0.0, 0.0, 6.0)

func _process(delta: float) -> void:
	var target_x: float
	var target_z: float
	var lerp_t: float
	if player != null and is_instance_valid(player):
		target_x = player.global_position.x + offset.x
		target_z = player.global_position.z + offset.z
		lerp_t = 1.0 - exp(-12.0 * delta)
	elif follow_target != null:
		target_x = follow_target.global_position.x
		target_z = follow_target.global_position.z
		lerp_t = 0.08
	else:
		return
	global_position.x = lerp(global_position.x, target_x, lerp_t)
	global_position.z = lerp(global_position.z, target_z, lerp_t)
