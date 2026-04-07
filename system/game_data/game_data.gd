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

func _ready() -> void:
	instance = self

func reset_for_new_game() -> void:
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
	sector_map = SectorMapData.new()
	sector_map.generate()
	enemy_forces = EnemyForces.new()
	enemy_forces.initialize_sectors(sector_map.sectors.size(), 1800)

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

func buy_damage_upgrade() -> bool:
	var cost_scrap: int = 20 + cleared_runs * 4
	if not spend(cost_scrap, 0):
		return false
	player_damage += 3.0
	return true

func buy_fire_rate_upgrade() -> bool:
	var cost_scrap: int = 25 + cleared_runs * 5
	if not spend(cost_scrap, 1):
		return false
	player_fire_rate = maxf(0.08, player_fire_rate - 0.015)
	return true

func buy_hull_upgrade() -> bool:
	var cost_scrap: int = 18 + cleared_runs * 4
	if not spend(cost_scrap, 0):
		return false
	player_ship_max_hull += 12
	player_max_hull += 12
	player_hull = player_max_hull
	return true

func buy_mining_upgrade() -> bool:
	var cost_scrap: int = 15 + cleared_runs * 3
	if not spend(cost_scrap, 0):
		return false
	player_mining_damage += 4.0
	return true
