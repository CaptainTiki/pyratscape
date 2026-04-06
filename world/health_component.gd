extends Node
class_name HealthComponent

signal destroyed
signal damaged

@export var max_health: int = 100
var health: int

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	damaged.emit()
	if health <= 0:
		destroyed.emit()
