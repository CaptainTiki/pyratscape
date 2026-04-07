extends Node
class_name WorldSimulation

signal simulation_ticked
signal world_time_advanced(minutes: float)
signal forced_deploy_required

@export_group("Timing")
@export var simulation_tick_interval: float = 0.1  # seconds between ticks
@export var initial_resources_per_sector: int = 1800

@export_group("Enemy Behavior")
@export var enemy_wave_interval_min_minutes: float = 6.0
@export var enemy_wave_interval_max_minutes: float = 10.0
@export var factory_production_time_minutes: float = 3.5
@export var enemy_mining_rate: float = 2.0  # scrap per tick
@export var enemy_forced_deploy_threshold: int = 10

var enemy_forces: EnemyForces = null
var sector_map: SectorMapData = null
var current_player_sector_id: int = 0

var _tick_timer: float = 0.0
var _last_wave_time_minutes: Dictionary[int, float] = {}  # sector_id -> time since last wave
var _factory_production_timer: Dictionary[int, float] = {}  # sector_id -> production timer
var _simulation_paused: bool = false

func _ready() -> void:
	# Initialize all factory production timers
	if enemy_forces == null or enemy_forces.sectors.is_empty():
		return

	for sector_id in enemy_forces.sectors.keys():
		_last_wave_time_minutes[sector_id] = randf_range(enemy_wave_interval_min_minutes, enemy_wave_interval_max_minutes)
		_factory_production_timer[sector_id] = randf_range(0.0, factory_production_time_minutes)

func _process(delta: float) -> void:
	if enemy_forces == null or _simulation_paused:
		return

	_tick_timer += delta
	if _tick_timer >= simulation_tick_interval:
		_tick_timer -= simulation_tick_interval
		_run_simulation_tick()

func initialize(enemy_forces_ref: EnemyForces, sector_map_ref: SectorMapData, player_sector_id: int) -> void:
	enemy_forces = enemy_forces_ref
	sector_map = sector_map_ref
	current_player_sector_id = player_sector_id
	_ready()

func set_current_player_sector(sector_id: int) -> void:
	current_player_sector_id = sector_id

func advance_time_minutes(minutes: float) -> void:
	if enemy_forces == null:
		return

	# Fast-forward the simulation by the given minutes
	var ticks_to_run = int(minutes * 60.0 / simulation_tick_interval)
	for _i in range(ticks_to_run):
		_run_simulation_tick()

	enemy_forces.advance_game_time(minutes)
	world_time_advanced.emit(minutes)

func get_enemies_at_station(sector_id: int) -> int:
	if enemy_forces == null:
		return 0
	return enemy_forces.get_enemies_in_sector(sector_id)

func get_sector_resources(sector_id: int) -> int:
	if enemy_forces == null:
		return 0
	var forces = enemy_forces.get_sector_forces(sector_id)
	return forces.available_resources if forces else 0

func pause_simulation() -> void:
	_simulation_paused = true

func resume_simulation() -> void:
	_simulation_paused = false

func _run_simulation_tick() -> void:
	if enemy_forces == null or enemy_forces.sectors.is_empty():
		return

	var tick_time_minutes = simulation_tick_interval / 60.0

	for sector_id in enemy_forces.sectors.keys():
		var forces = enemy_forces.get_sector_forces(sector_id)
		if forces == null:
			continue

		# Process mining (consume resources)
		_process_mining(sector_id, forces, tick_time_minutes)

		# Process factory production
		_process_factory_production(sector_id, forces, tick_time_minutes)

		# Process random enemy movement (MVP: simple random)
		_process_enemy_movement(sector_id, forces, tick_time_minutes)

		# Process wave spawning (enemy reinforcements)
		_process_wave_spawning(sector_id, forces, tick_time_minutes)

	# Check forced deployment
	_check_forced_deployment()

	simulation_ticked.emit()

func _process_mining(sector_id: int, forces: EnemyForces.SectorForces, tick_time_minutes: float) -> void:
	# Miners consume resources
	var total_miners = forces.miner_count
	if total_miners > 0 and forces.available_resources > 0:
		var resources_to_consume = int(total_miners * enemy_mining_rate * tick_time_minutes)
		enemy_forces.consume_resources_in_sector(sector_id, resources_to_consume)

func _process_factory_production(sector_id: int, forces: EnemyForces.SectorForces, tick_time_minutes: float) -> void:
	# Factories produce new fighters, but only if they have resources
	var factory_count = forces.factory_count
	if factory_count == 0:
		return

	if not _factory_production_timer.has(sector_id):
		_factory_production_timer[sector_id] = factory_production_time_minutes

	_factory_production_timer[sector_id] -= tick_time_minutes * factory_count

	while _factory_production_timer[sector_id] <= 0.0:
		# Check if factory has resources to build
		if forces.available_resources >= 100:  # Cost: 100 scrap per ship
			enemy_forces.consume_resources_in_sector(sector_id, 100)
			enemy_forces.add_fighter_to_sector(sector_id)
			_factory_production_timer[sector_id] += factory_production_time_minutes
		else:
			# Out of resources, pause production
			_factory_production_timer[sector_id] = factory_production_time_minutes
			break

func _process_enemy_movement(sector_id: int, forces: EnemyForces.SectorForces, tick_time_minutes: float) -> void:
	# MVP: Random movement
	# Occasionally, a sector sends 1-2 enemies to a random adjacent sector
	if randf() < 0.02:  # 2% chance per tick
		var total_enemies = forces.fighter_count + forces.miner_count
		if total_enemies > 1:
			# Pick a random adjacent sector
			var adjacent_sectors = _get_adjacent_sectors(sector_id)
			if not adjacent_sectors.is_empty():
				var target_sector = adjacent_sectors[randi() % adjacent_sectors.size()]
				# Send a random enemy
				if randf() < 0.5 and forces.fighter_count > 0:
					enemy_forces.remove_enemy_from_sector(sector_id, "fighter")
					enemy_forces.add_fighter_to_sector(target_sector)
				elif forces.miner_count > 0:
					enemy_forces.remove_enemy_from_sector(sector_id, "miner")
					enemy_forces.add_miner_to_sector(target_sector)

func _process_wave_spawning(sector_id: int, forces: EnemyForces.SectorForces, tick_time_minutes: float) -> void:
	# Reinforcement waves spawn at intervals
	if not _last_wave_time_minutes.has(sector_id):
		_last_wave_time_minutes[sector_id] = 0.0

	_last_wave_time_minutes[sector_id] += tick_time_minutes

	var wave_interval = randf_range(enemy_wave_interval_min_minutes, enemy_wave_interval_max_minutes)
	if _last_wave_time_minutes[sector_id] >= wave_interval:
		_last_wave_time_minutes[sector_id] = 0.0

		# Spawn a small wave (2-4 fighters) if sector has activity
		if forces.fighter_count > 0 or forces.factory_count > 0:
			var wave_size = randi_range(2, 4)
			for _i in range(wave_size):
				enemy_forces.add_fighter_to_sector(sector_id)

func _get_adjacent_sectors(sector_id: int) -> Array[int]:
	var adjacent: Array[int] = []
	if sector_map == null:
		return adjacent

	for connection in sector_map.connections:
		if connection.x == sector_id:
			adjacent.append(connection.y)
		elif connection.y == sector_id:
			adjacent.append(connection.x)

	return adjacent

func _check_forced_deployment() -> void:
	var enemies_at_station = get_enemies_at_station(current_player_sector_id)
	if enemies_at_station >= enemy_forced_deploy_threshold:
		forced_deploy_required.emit()
