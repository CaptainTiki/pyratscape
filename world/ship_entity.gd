extends CharacterBody3D
class_name ShipEntity

var projectile_parent: Node3D = null:
	set(value):
		projectile_parent = value
		_on_projectile_parent_set()
var health: HealthComponent = null

func _on_projectile_parent_set() -> void:
	pass

func apply_damage(amount: int) -> void:
	if health != null:
		health.take_damage(amount)

func apply_collision_damage(amount: int) -> void:
	apply_damage(amount)
