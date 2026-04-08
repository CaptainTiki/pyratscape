extends BaseComponent
class_name RocketComponent

@export var damage: float = 40.0
@export var count: int = 4

func _init() -> void:
	component_type = "rocket"
	slot_type = "rocket"
	icon_color = Color(0.95, 0.6, 0.1)
	size = Vector2i(1, 1)
