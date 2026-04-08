extends BaseComponent
class_name EngineComponent

@export var move_speed: float = 28.0
@export var boost_multiplier: float = 1.7

func _init() -> void:
	component_type = "engine"
	slot_type = "engine"
	icon_color = Color(0.2, 0.85, 0.4)
	size = Vector2i(1, 1)
