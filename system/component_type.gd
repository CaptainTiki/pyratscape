extends RefCounted
class_name ComponentType

enum Type {
	ENGINE = 0,
	WEAPON = 1,
	ROCKET = 2,
	POWER = 3,
	SHIELD = 4,
	TRACTOR = 5
}

static func type_to_string(type: Type) -> String:
	match type:
		Type.ENGINE:
			return "Engine"
		Type.WEAPON:
			return "Weapon"
		Type.ROCKET:
			return "Rocket"
		Type.POWER:
			return "Power"
		Type.SHIELD:
			return "Shield"
		Type.TRACTOR:
			return "Tractor"
		_:
			return "Unknown"

static func type_to_slot_prefix(type: Type) -> String:
	match type:
		Type.ENGINE:
			return "engine"
		Type.WEAPON:
			return "weapon"
		Type.ROCKET:
			return "rocket"
		Type.POWER:
			return "power"
		Type.SHIELD:
			return "shield"
		Type.TRACTOR:
			return "tractor"
		_:
			return ""

static func slot_prefix_to_type(prefix: String) -> Type:
	match prefix:
		"engine":
			return Type.ENGINE
		"weapon":
			return Type.WEAPON
		"rocket":
			return Type.ROCKET
		"power":
			return Type.POWER
		"shield":
			return Type.SHIELD
		"tractor":
			return Type.TRACTOR
		_:
			return Type.ENGINE

static func get_all_types() -> Array[ComponentType.Type]:
	return [
		Type.ENGINE,
		Type.WEAPON,
		Type.ROCKET,
		Type.POWER,
		Type.SHIELD,
		Type.TRACTOR
	]
