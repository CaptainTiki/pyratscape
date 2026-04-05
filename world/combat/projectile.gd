extends Area3D
class_name Projectile

@export var speed: float = 42.0
@export var damage: float = 12.0
@export var lifetime: float = 2.4
@export var is_mining: bool = false

var direction: Vector3 = Vector3.ZERO
var source: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == source:
		return
	if body.has_method("apply_damage"):
		body.apply_damage(damage)
		queue_free()
	elif is_mining and body.has_method("apply_mining_damage"):
		body.apply_mining_damage(damage)
		queue_free()

func _on_area_entered(area: Area3D) -> void:
	if area == source:
		return
	if area.has_method("apply_damage"):
		area.apply_damage(damage)
		queue_free()
	elif is_mining and area.has_method("apply_mining_damage"):
		area.apply_mining_damage(damage)
		queue_free()
