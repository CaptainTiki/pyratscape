extends BaseComponent
class_name ShieldComponent

@export var shield_hp: int = 50
@export var recharge_rate: float = 5.0

func _init() -> void:
	component_type = "shield"
	slot_type = "shield"
	icon_color = Color(0.3, 0.5, 1.0)
	size = Vector2i(1, 1)
