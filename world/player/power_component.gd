extends BaseComponent
class_name PowerComponent

@export var power_output: float = 10.0

func _init() -> void:
	component_type = "power"
	slot_type = "power"
	icon_color = Color(0.9, 0.9, 0.2)
	size = Vector2i(1, 1)
