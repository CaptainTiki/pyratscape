extends Node
class_name GameData

static var instance: GameData

var scrap: int = 0
var crystals: int = 0
var station_integrity: int = 100
var player_ship_max_hull: int = 100  # permanent value; only changed by upgrades
var player_max_hull: int = 100       # operational value; temporarily lowered in pod mode
var player_hull: int = 100
var player_damage: float = 12.0
var player_fire_rate: float = 0.22
var player_move_speed: float = 28.0
var player_boost_multiplier: float = 1.7
var player_mining_damage: float = 18.0
var player_tractor_range: float = 7.5
var cleared_runs: int = 0
var sector_map: SectorMapData = null
var enemy_forces: EnemyForces = null
var ship_config: Dictionary = {}  # slot_name: BaseComponent Resource path or data
var component_inventory: Array[BaseComponent] = []

var static_world: StaticWorldData = null

func _ready() -> void:
	instance = self

func reset_for_new_game() -> void:
	ship_config.clear()
	component_inventory.clear()
	_add_starter_components()
	scrap = 0
	crystals = 0
	station_integrity = 100
	player_ship_max_hull = 100
	player_max_hull = 100
	player_hull = player_max_hull
	player_damage = 12.0
	player_fire_rate = 0.22
	player_move_speed = 28.0
	player_boost_multiplier = 1.7
	player_mining_damage = 18.0
	player_tractor_range = 7.5
	cleared_runs = 0
	# Load the hand-authored test world instead of the procedural generator.
	# The static world provides labeled sectors, factories, and an explicit
	# enemy home so the simulation has a deterministic substrate to run on.
	static_world = TestWorld01.build()
	sector_map = SectorMapData.new()
	sector_map.load_from_static(static_world)
	enemy_forces = EnemyForces.new()
	enemy_forces.initialize_from_static(static_world)

func save_ship_config():
	var file = FileAccess.open("user://ship_config.json", FileAccess.WRITE)
	if file:
		var data = {}
		for slot in ship_config:
			data[slot] = {
				"slot_type": ship_config[slot].slot_type if ship_config[slot] else "",
				"icon_color": ship_config[slot].icon_color.to_html(false) if ship_config[slot] else ""
			}
		file.store_string(JSON.stringify(data))
		file.close()

func load_ship_config():
	var file = FileAccess.open("user://ship_config.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if data:
			for slot in data:
				if data[slot].slot_type != "":
					# Load proto component by type/color
					ship_config[slot] = BaseComponent.new()
					ship_config[slot].slot_type = data[slot].slot_type
					ship_config[slot].icon_color = Color.html(data[slot].icon_color)

func _add_starter_components() -> void:
	var engine_l := EngineComponent.new()
	engine_l.name = "Basic Engine"
	component_inventory.append(engine_l)

	var engine_r := EngineComponent.new()
	engine_r.name = "Basic Engine"
	component_inventory.append(engine_r)

	var cannon := WeaponComponent.new()
	cannon.name = "Pulse Cannon"
	component_inventory.append(cannon)

	var tractor := TractorComponent.new()
	tractor.name = "Tractor Beam"
	component_inventory.append(tractor)

	var power := PowerComponent.new()
	power.name = "Power Cell"
	component_inventory.append(power)

func repair_player_full() -> void:
	player_hull = player_max_hull

func restore_ship_hull() -> void:
	player_max_hull = player_ship_max_hull
	player_hull = player_ship_max_hull

func add_scrap(amount: int) -> void:
	scrap += amount

func add_crystals(amount: int) -> void:
	crystals += amount

func can_afford(cost_scrap: int, cost_crystals: int) -> bool:
	return scrap >= cost_scrap and crystals >= cost_crystals

func spend(cost_scrap: int, cost_crystals: int) -> bool:
	if not can_afford(cost_scrap, cost_crystals):
		return false
	scrap -= cost_scrap
	crystals -= cost_crystals
	return true
