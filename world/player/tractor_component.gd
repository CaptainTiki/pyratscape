extends BaseComponent
class_name TractorComponent

@export var range: float = 7.5

func _init() -> void:
	component_type = "tractor"
	slot_type = "tractor"
	icon_color = Color(0.5, 0.9, 0.95)
	size = Vector2i(1, 1)
