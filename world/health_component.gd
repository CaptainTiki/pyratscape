extends Node
class_name HealthComponent

signal destroyed

@export var max_health: int = 100
var health: int

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if health <= 0:
		destroyed.emit()
