extends BaseComponent
class_name WeaponComponent

@export var damage: float = 12.0
@export var fire_rate: float = 0.22

func _init() -> void:
	component_type = "weapon"
	slot_type = "weapon"
	icon_color = Color(0.9, 0.3, 0.2)
	size = Vector2i(1, 1)
