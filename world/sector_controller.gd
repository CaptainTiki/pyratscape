extends Node
class_name SectorController

signal sector_changed
signal dock_sequence_finished

@onready var spawner: SectorSpawner = $SectorSpawner
@onready var reporter: SectorReporter = $SectorReporter

var station_manager: StationManager = null
var enemy_spawner: EnemySpawner = null
var activity_tracker: ActivityTracker = null

var sector_state: int = WorldRoot.SectorState.DEPLOYING
var target_asteroid_count: int = 7

var player: PlayerShip:
	get: return spawner.player if spawner else null
var asteroids_remaining: int:
	get: return spawner.asteroids_remaining if spawner else 0
var mission_message: String:
	get: return reporter.mission_message if reporter else ""
	set(value):
		if reporter != null:
			reporter.mission_message = value
var enemies_remaining: int:
	get: return enemy_spawner.enemies_remaining if enemy_spawner else 0
var activity: float:
	get: return activity_tracker.activity if activity_tracker else 0.0
var run_complete: bool:
	get: return activity_tracker.run_complete if activity_tracker else false

func setup(world: WorldRoot) -> void:
	station_manager = world.station_manager
	enemy_spawner = world.enemy_spawner
	activity_tracker = world.activity_tracker
	reporter.activity_tracker = activity_tracker
	spawner.setup(world)

	if not station_manager.deploy_finished.is_connected(on_station_deploy_finished):
		station_manager.deploy_finished.connect(on_station_deploy_finished)
	if not station_manager.inbound_finished.is_connected(on_station_inbound_finished):
		station_manager.inbound_finished.connect(on_station_inbound_finished)
	if not station_manager.dock_finished.is_connected(on_station_dock_finished):
		station_manager.dock_finished.connect(on_station_dock_finished)
	if not station_manager.redeploy_finished.is_connected(on_station_redeploy_finished):
		station_manager.redeploy_finished.connect(on_station_redeploy_finished)
	if not enemy_spawner.enemy_destroyed.is_connected(on_enemy_destroyed):
		enemy_spawner.enemy_destroyed.connect(on_enemy_destroyed)
	if not enemy_spawner.wave_spawned.is_connected(on_wave_spawned):
		enemy_spawner.wave_spawned.connect(on_wave_spawned)
	if not activity_tracker.activity_changed.is_connected(on_activity_changed):
		activity_tracker.activity_changed.connect(on_activity_changed)
	if not activity_tracker.run_completed.is_connected(on_run_completed):
		activity_tracker.run_completed.connect(on_run_completed)
	if not spawner.asteroid_mined_out.is_connected(on_asteroid_mined_out):
		spawner.asteroid_mined_out.connect(on_asteroid_mined_out)

func begin_sector_cycle() -> void:
	spawner.clear()
	_read_sector_params()
	sector_state = WorldRoot.SectorState.DEPLOYING
	reporter.deploying()
	station_manager.begin_deploy()
	spawner.spawn_asteroids(target_asteroid_count)
	sector_changed.emit()

func redeploy_sector() -> void:
	begin_sector_cycle()

func try_interact_at_station() -> bool:
	if sector_state in [WorldRoot.SectorState.DOCKING, WorldRoot.SectorState.DOCKED]:
		return true
	if not station_manager.station_present:
		call_station_to_sector()
		return false
	if not station_manager.is_player_in_range(spawner.player):
		reporter.move_closer_to_dock()
		sector_changed.emit()
		return false
	if GameData.instance == null:
		return false
	GameData.instance.repair_player_full()
	sector_state = WorldRoot.SectorState.DOCKING
	station_manager.begin_dock()
	reporter.docking()
	if spawner.player != null and is_instance_valid(spawner.player):
		spawner.player.visible = false
		spawner.player.process_mode = Node.PROCESS_MODE_DISABLED
	enemy_spawner.stop_spawning()
	activity_tracker.stop_tracking()
	sector_changed.emit()
	return true

func call_station_to_sector() -> void:
	if station_manager.station_present or sector_state in [WorldRoot.SectorState.STATION_INBOUND, WorldRoot.SectorState.DOCKING, WorldRoot.SectorState.DOCKED]:
		return
	sector_state = WorldRoot.SectorState.STATION_INBOUND
	station_manager.begin_inbound()
	reporter.station_inbound()
	sector_changed.emit()

func apply_station_damage(amount: int) -> void:
	station_manager.apply_damage(amount)
	if GameData.instance != null and GameData.instance.station_integrity <= 0:
		reporter.station_fallen()
	sector_changed.emit()

func register_pickup(pickup: ResourcePickup) -> void:
	spawner.register_pickup(pickup)

func get_activity_display() -> int:
	return reporter.get_activity_display()

# --- Station event handlers ---

func on_station_deploy_finished() -> void:
	spawner.spawn_player()
	sector_state = WorldRoot.SectorState.ACTIVE
	station_manager.depart_after_launch()
	enemy_spawner.start_spawning()
	activity_tracker.start_tracking()
	reporter.station_launched()
	sector_changed.emit()

func on_station_inbound_finished() -> void:
	sector_state = WorldRoot.SectorState.ACTIVE
	reporter.station_on_site()
	sector_changed.emit()

func on_station_dock_finished() -> void:
	sector_state = WorldRoot.SectorState.DOCKED
	reporter.dock_complete()
	sector_changed.emit()
	dock_sequence_finished.emit()

func on_station_redeploy_finished() -> void:
	sector_state = WorldRoot.SectorState.ACTIVE
	reporter.redeploy_complete()
	sector_changed.emit()

# --- Combat / activity event handlers ---

func on_enemy_destroyed(_enemy: EnemyShip) -> void:
	activity_tracker.add_activity(2.0)
	reporter.enemy_down()
	_check_win_condition()
	sector_changed.emit()

func on_wave_spawned() -> void:
	reporter.wave_incoming()
	sector_changed.emit()

func on_asteroid_mined_out() -> void:
	activity_tracker.add_activity(5.0)
	reporter.asteroid_mined()
	_check_win_condition()
	sector_changed.emit()

func on_activity_changed() -> void:
	_check_win_condition()
	sector_changed.emit()

func on_run_completed() -> void:
	reporter.run_complete()
	sector_changed.emit()
	if GameData.instance != null:
		GameData.instance.cleared_runs += 1
		if GameData.instance.sector_map != null:
			var current: SectorMapData.SectorData = GameData.instance.sector_map.get_current_sector()
			if current != null:
				current.is_cleared = true

# --- Internal helpers ---

func _check_win_condition() -> void:
	activity_tracker.check_win_condition(enemy_spawner.enemies_remaining)

func _read_sector_params() -> void:
	var map_sector: SectorMapData.SectorData = null
	if GameData.instance != null and GameData.instance.sector_map != null:
		map_sector = GameData.instance.sector_map.get_current_sector()
	var cap: int = 2
	var asteroid_count: int = 7
	var danger: float = 0.3
	if map_sector != null:
		cap = maxi(1, map_sector.enemy_fleet_size)
		asteroid_count = map_sector.asteroid_count
		danger = map_sector.danger_level
	target_asteroid_count = asteroid_count
	enemy_spawner.reset(cap)
	activity_tracker.reset(danger)
