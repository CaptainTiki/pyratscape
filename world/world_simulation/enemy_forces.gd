extends RefCounted
class_name EnemyForces

class SectorForces:
	var sector_id: int = 0
	var available_resources: int = 0
	var miner_count: int = 0
	var fighter_count: int = 0
	var factory_count: int = 0
	var enemy_ships_moving_here: int = 0

var sectors: Dictionary[int, SectorForces] = {}
var total_game_time_minutes: float = 0.0

func _init() -> void:
	pass

func initialize_sectors(sector_count: int, initial_resources_per_sector: int) -> void:
	sectors.clear()
	for i in range(sector_count):
		var sector_forces = SectorForces.new()
		sector_forces.sector_id = i
		sector_forces.available_resources = initial_resources_per_sector
		sector_forces.miner_count = 0
		sector_forces.fighter_count = 0
		sector_forces.factory_count = 0
		sector_forces.enemy_ships_moving_here = 0
		sectors[i] = sector_forces

	# Seed with initial enemy distribution (simple: spread some fighters around)
	_distribute_initial_enemies(sector_count)

func reset_for_new_game() -> void:
	sectors.clear()
	total_game_time_minutes = 0.0

func get_enemies_in_sector(sector_id: int) -> int:
	var forces = sectors.get(sector_id)
	if forces == null:
		return 0
	return forces.fighter_count + forces.miner_count + forces.factory_count

func get_sector_forces(sector_id: int) -> SectorForces:
	return sectors.get(sector_id)

func add_resources_to_sector(sector_id: int, amount: int) -> void:
	var forces = sectors.get(sector_id)
	if forces != null:
		forces.available_resources += amount

func consume_resources_in_sector(sector_id: int, amount: int) -> int:
	var forces = sectors.get(sector_id)
	if forces == null:
		return 0
	var consumed = mini(amount, forces.available_resources)
	forces.available_resources -= consumed
	return consumed

func add_fighter_to_sector(sector_id: int) -> void:
	var forces = sectors.get(sector_id)
	if forces != null:
		forces.fighter_count += 1

func add_miner_to_sector(sector_id: int) -> void:
	var forces = sectors.get(sector_id)
	if forces != null:
		forces.miner_count += 1

func remove_enemy_from_sector(sector_id: int, enemy_type: String = "fighter") -> void:
	var forces = sectors.get(sector_id)
	if forces == null:
		return

	match enemy_type:
		"fighter":
			forces.fighter_count = maxi(0, forces.fighter_count - 1)
		"miner":
			forces.miner_count = maxi(0, forces.miner_count - 1)
		"factory":
			forces.factory_count = maxi(0, forces.factory_count - 1)

func set_enemies_in_sector(sector_id: int, fighter_count: int, miner_count: int = 0, factory_count: int = 0) -> void:
	var forces = sectors.get(sector_id)
	if forces != null:
		forces.fighter_count = fighter_count
		forces.miner_count = miner_count
		forces.factory_count = factory_count

func advance_game_time(minutes: float) -> void:
	total_game_time_minutes += minutes

func _distribute_initial_enemies(sector_count: int) -> void:
	# Seed with a few scattered enemies to make the world feel dangerous
	# Start sector (0) has minimal threats
	if sector_count > 0:
		sectors[0].fighter_count = 0

	# Distribute a handful of fighters across other sectors
	var enemy_seeds = [1, 2, 3, 1, 2]  # Simple pattern: 5 fighters across early sectors
	for i in range(mini(enemy_seeds.size(), sector_count - 1)):
		if i + 1 < sector_count:
			sectors[i + 1].fighter_count = enemy_seeds[i]
