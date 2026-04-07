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
@export var factory_production_time_minutes: float = 4.5  # increased to slow down production
@export var enemy_mining_rate: float = 2.0  # scrap per tick
@export var enemy_forced_deploy_threshold: int = 10

@export_group("Factories")
@export var factory_sector_ids: Array[int] = [1, 6, 11]  # hardcoded factory locations
@export var factory_push_chance: float = 0.5  # chance a newly produced ship spawns one step toward player

@export_group("Home Defense")
@export var home_defense_production_time_minutes: float = 13.5  # 1/3 of factory speed

@export_group("Enemy Territory")
@export var max_enemy_garrison: int = 8  # target count at the enemy home sector
@export var garrison_falloff_per_jump: int = 2  # target count decreases by this each BFS step outward

var enemy_forces: EnemyForces = null
var sector_map: SectorMapData = null
var current_player_sector_id: int = 0

var _tick_timer: float = 0.0
var _last_wave_time_minutes: Dictionary[int, float] = {}  # sector_id -> time since last wave
var _factory_production_timer: Dictionary[int, float] = {}  # sector_id -> production timer
var _home_defense_timer: float = 0.0  # timer for home sector spawning
var _simulation_paused: bool = false

# Enemy territory model: enemy home = factory farthest from player's start sector (0).
# Ships flow outward from the enemy home toward the player, with a falloff gradient.
var _enemy_home_sector_id: int = -1
var _enemy_home_override: int = -1  # set by static world if available
var _player_home_sector_id: int = 0  # set from static world player_start, default 0
var _distance_from_enemy_home: Dictionary[int, int] = {}
var _distance_to_player_home: Dictionary[int, int] = {}

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

func initialize(enemy_forces_ref: EnemyForces, sector_map_ref: SectorMapData, player_sector_id: int, static_world: StaticWorldData = null) -> void:
	enemy_forces = enemy_forces_ref
	sector_map = sector_map_ref
	current_player_sector_id = player_sector_id

	# When a static world is provided, its labeled roles override the
	# hardcoded exports. This is the path the game actually takes now.
	if static_world != null:
		var static_factories := static_world.get_factory_ids()
		if not static_factories.is_empty():
			factory_sector_ids = static_factories
		var player_start := static_world.get_player_start_id()
		if player_start >= 0:
			current_player_sector_id = player_start
			_player_home_sector_id = player_start
		var enemy_home := static_world.get_enemy_home_id()
		if enemy_home >= 0:
			_enemy_home_override = enemy_home

	# Factories are already set on enemy_forces by initialize_from_static(),
	# but keep this call for the procedural path.
	if enemy_forces != null and enemy_forces.get_factory_sectors().is_empty():
		enemy_forces.set_factory_sectors(factory_sector_ids)

	_determine_enemy_home()
	_precompute_territory_distances()

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

		# Process factory production (factories always produce, ignoring resources for now)
		if enemy_forces.has_factory(sector_id):
			_process_factory_production(sector_id, forces, tick_time_minutes)

	# Process home defense production (spawn enemies at sector 0)
	_process_home_defense_production(tick_time_minutes)

	# Process fleet intent (spread ships across sectors)
	_process_fleet_intent(tick_time_minutes)

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
	# Factories produce new fighters continuously (no resource cost for MVP)
	var factory_count = forces.factory_count
	if factory_count == 0:
		return

	if not _factory_production_timer.has(sector_id):
		_factory_production_timer[sector_id] = factory_production_time_minutes

	_factory_production_timer[sector_id] -= tick_time_minutes * factory_count

	while _factory_production_timer[sector_id] <= 0.0:
		# Produce a new fighter. With some probability, push it one step toward
		# the player's home sector so factories act as sources of an outward flow
		# instead of just piling up ships in-place.
		var spawn_sector = sector_id
		if randf() < factory_push_chance:
			var push_target = _pick_adjacent_toward_player(sector_id)
			if push_target >= 0:
				spawn_sector = push_target
		enemy_forces.add_fighter_to_sector(spawn_sector)
		_factory_production_timer[sector_id] += factory_production_time_minutes

func _pick_adjacent_toward_player(sector_id: int) -> int:
	# Return a random adjacent sector strictly closer to the player's home (sector 0).
	# Returns -1 if no such neighbor exists.
	var my_dist = _distance_to_player_home.get(sector_id, 999)
	var candidates: Array[int] = []
	for neighbor in _get_adjacent_sectors(sector_id):
		var nd = _distance_to_player_home.get(neighbor, 999)
		if nd < my_dist:
			candidates.append(neighbor)
	if candidates.is_empty():
		return -1
	return candidates[randi() % candidates.size()]

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

func _process_home_defense_production(tick_time_minutes: float) -> void:
	# Slowly spawn enemies at home base (sector 0) to threaten the player
	# Rate is 1/3 of factory production
	if enemy_forces == null:
		return

	_home_defense_timer -= tick_time_minutes

	while _home_defense_timer <= 0.0:
		# Produce a home defense fighter at sector 0
		enemy_forces.add_fighter_to_sector(_player_home_sector_id)
		_home_defense_timer += home_defense_production_time_minutes

func _process_fleet_intent(tick_time_minutes: float) -> void:
	# Simple intent: spread ships toward lower-count sectors, biased toward home base
	# Home base = sector 0 (where player starts) - should have higher concentration
	# Other sectors should have fewer ships, with a gradient outward

	if enemy_forces == null or enemy_forces.sectors.is_empty():
		return

	# Occasionally check if we should move ships to balance the map
	if randf() > 0.01:  # 1% chance per tick (~6 times per minute)
		return

	# Find a sector with excess ships and one with deficit
	var excess_sector = -1
	var deficit_sector = -1
	var max_excess = 0
	var max_deficit = 999

	for sector_id in enemy_forces.sectors.keys():
		var current_count = enemy_forces.get_enemies_in_sector(sector_id)
		var target_count = _get_target_enemy_count_for_sector(sector_id)

		if current_count > target_count and current_count > max_excess:
			max_excess = current_count
			excess_sector = sector_id

		if current_count < target_count and target_count < max_deficit:
			max_deficit = target_count
			deficit_sector = sector_id

	# Move a ship from excess to deficit
	if excess_sector >= 0 and deficit_sector >= 0:
		if enemy_forces.get_sector_forces(excess_sector).fighter_count > 0:
			enemy_forces.remove_enemy_from_sector(excess_sector, "fighter")
			enemy_forces.add_fighter_to_sector(deficit_sector)

func _get_target_enemy_count_for_sector(sector_id: int) -> int:
	# Garrison target scales with BFS distance from the enemy home sector.
	# Strongest concentration at the enemy home, thinning out toward the player.
	# Player's own home is clamped low so the player isn't immediately swarmed.
	if sector_id == _player_home_sector_id:
		return 1

	var dist = _distance_from_enemy_home.get(sector_id, -1)
	if dist < 0:
		# Fallback if territory wasn't precomputed yet.
		dist = _calculate_sector_distance(_enemy_home_sector_id, sector_id)

	return maxi(1, max_enemy_garrison - dist * garrison_falloff_per_jump)

func _determine_enemy_home() -> void:
	# Prefer the explicit is_enemy_home flag from a static world.
	# Otherwise fall back to: the factory sector furthest from the player's home.
	# Final fallback: the first sector in the map.
	if _enemy_home_override >= 0:
		_enemy_home_sector_id = _enemy_home_override
		return

	_enemy_home_sector_id = -1
	var best_dist := -1
	for factory_id in factory_sector_ids:
		var d := _calculate_sector_distance(_player_home_sector_id, factory_id)
		if d > best_dist:
			best_dist = d
			_enemy_home_sector_id = factory_id

	if _enemy_home_sector_id < 0 and enemy_forces != null and not enemy_forces.sectors.is_empty():
		_enemy_home_sector_id = enemy_forces.sectors.keys()[0]

func _precompute_territory_distances() -> void:
	# Cache BFS distances from both anchor sectors so per-tick logic is cheap.
	_distance_from_enemy_home.clear()
	_distance_to_player_home.clear()
	if enemy_forces == null:
		return
	for sector_id in enemy_forces.sectors.keys():
		_distance_from_enemy_home[sector_id] = _calculate_sector_distance(_enemy_home_sector_id, sector_id)
		_distance_to_player_home[sector_id] = _calculate_sector_distance(_player_home_sector_id, sector_id)

func _calculate_sector_distance(from_id: int, to_id: int) -> int:
	# BFS to find shortest path distance in sector graph
	if from_id == to_id:
		return 0

	if sector_map == null:
		return 0

	var visited: Dictionary[int, bool] = {}
	var queue: Array[Array] = [[from_id, 0]]  # [sector_id, distance]

	while queue.size() > 0:
		var current = queue.pop_front()
		var current_id = current[0]
		var current_dist = current[1]

		if visited.has(current_id):
			continue

		visited[current_id] = true

		if current_id == to_id:
			return current_dist

		# Check adjacent sectors
		for connection in sector_map.connections:
			var neighbor = -1
			if connection.x == current_id:
				neighbor = connection.y
			elif connection.y == current_id:
				neighbor = connection.x

			if neighbor >= 0 and not visited.has(neighbor):
				queue.append([neighbor, current_dist + 1])

	return 999  # unreachable

func _check_forced_deployment() -> void:
	var enemies_at_station = get_enemies_at_station(current_player_sector_id)
	if enemies_at_station >= enemy_forced_deploy_threshold:
		forced_deploy_required.emit()
