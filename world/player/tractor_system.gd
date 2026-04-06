extends Node
class_name TractorSystem

@export var tractor_range: float = 7.5

# Set by PlayerShip in _ready()
var ship: Node3D = null
var tractor_area: Area3D = null
var tractor_visual: Node3D = null

var tractor_active: bool = false

func tick(_delta: float) -> void:
	tractor_active = Input.is_action_pressed("fire_tractor")
	tractor_visual.visible = false
	if not tractor_active:
		return
	var closest_pickup: ResourcePickup = null
	var closest_distance: float = INF
	for area in tractor_area.get_overlapping_areas():
		if area is ResourcePickup:
			var pickup: ResourcePickup = area as ResourcePickup
			pickup.magnet_to(ship)
			var distance: float = ship.global_position.distance_to(pickup.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_pickup = pickup
	if closest_pickup != null:
		_update_visual(closest_pickup.global_position)

func set_range(range_value: float) -> void:
	tractor_range = range_value
	var shape: CollisionShape3D = tractor_area.get_node("CollisionShape3D") as CollisionShape3D
	var sphere: SphereShape3D = shape.shape as SphereShape3D
	sphere.radius = tractor_range

func _update_visual(target_position: Vector3) -> void:
	tractor_visual.visible = true
	var from_point: Vector3 = ship.global_position
	tractor_visual.global_position = (from_point + target_position) * 0.5
	tractor_visual.look_at(target_position, Vector3.UP)
	tractor_visual.scale = Vector3(1.0, 1.0, from_point.distance_to(target_position))
