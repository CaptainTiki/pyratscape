extends Area3D
class_name ResourcePickup

enum PickupType {SCRAP, CRYSTAL}

@export var pickup_type: PickupType = PickupType.SCRAP
@export var amount: int = 5
@export var bob_speed: float = 2.0
@export var bob_height: float = 0.25

var bob_time: float = 0.0
var target_node: Node3D = null
var magnet_speed: float = 20.0
var start_y: float = 0.8
var repel_velocity: Vector3 = Vector3.ZERO
var repel_damping: float = 6.5
var collect_distance: float = 1.5

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	start_y = global_position.y
	_update_visuals()

func _physics_process(delta: float) -> void:
	bob_time += delta
	if target_node != null and is_instance_valid(target_node):
		global_position = global_position.move_toward(target_node.global_position, magnet_speed * delta)
		if target_node is PlayerShip and global_position.distance_to(target_node.global_position) <= collect_distance:
			_collect()
		return
	if repel_velocity.length() > 0.01:
		global_position += repel_velocity * delta
		repel_velocity = repel_velocity.move_toward(Vector3.ZERO, repel_damping * delta)
		global_position.y = start_y
	else:
		global_position.y = start_y + (sin(bob_time * bob_speed) * bob_height)

func magnet_to(node: Node3D) -> void:
	target_node = node
	repel_velocity = Vector3.ZERO

func repel_from(node: Node3D) -> void:
	target_node = null
	var push_direction: Vector3 = global_position - node.global_position
	push_direction.y = 0.0
	if push_direction.length() < 0.01:
		push_direction = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	push_direction = push_direction.normalized()
	repel_velocity = push_direction * 8.5

func _collect() -> void:
	if GameData.instance != null:
		if pickup_type == PickupType.SCRAP:
			GameData.instance.add_scrap(amount)
		else:
			GameData.instance.add_crystals(amount)
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body is PlayerShip:
		var player: PlayerShip = body as PlayerShip
		if player.tractor.tractor_active:
			_collect()
		else:
			repel_from(player)

func _on_area_entered(_area: Area3D) -> void:
	pass

func _update_visuals() -> void:
	var mesh_node: MeshInstance3D = $MeshInstance3D
	var material: StandardMaterial3D = mesh_node.material_override as StandardMaterial3D
	if pickup_type == PickupType.SCRAP:
		material.albedo_color = Color(0.9, 0.75, 0.35, 1)
		material.emission = Color(0.6, 0.45, 0.1, 1)
	else:
		material.albedo_color = Color(0.45, 1.0, 0.95, 1)
		material.emission = Color(0.15, 0.7, 0.8, 1)
