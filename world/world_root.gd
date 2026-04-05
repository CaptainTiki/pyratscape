extends Node3D
class_name WorldRoot

signal world_state_changed
signal dock_sequence_finished

const PLAYER_SCENE: PackedScene = preload("res://world/player/player_ship.tscn")
const ASTEROID_SCENE: PackedScene = preload("res://world/props/asteroid_node.tscn")

enum NodeState {
	DEPLOYING,
	ACTIVE,
	STATION_INBOUND,
	DOCKING,
	DOCKED,
	REDEPLOYING
}

@onready var actor_layer: Node3D = $Actors
@onready var projectile_layer: Node3D = $Projectiles
@onready var pickup_layer: Node3D = $Pickups
@onready var station_anchor: StaticBody3D = $StationAnchor
@onready var camera_rig: CameraRig = $CameraRig
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var activity_tracker: ActivityTracker = $ActivityTracker
@onready var station_manager: StationManager = $StationManager

var player: PlayerShip = null
var asteroids_remaining: int = 0
var node_state: NodeState = NodeState.DEPLOYING
var mission_message: String = "Deploying frontier station..."
var target_asteroid_count: int = 7

var enemies_remaining: int:
	get: return enemy_spawner.enemies_remaining if enemy_spawner else 0
var activity: float:
	get: return activity_tracker.activity if activity_tracker else 0.0
var run_complete: bool:
	get: return activity_tracker.run_complete if activity_tracker else false

func _ready() -> void:
	add_to_group("world_root")

	camera_rig.follow_target = station_anchor
	station_manager.station_anchor = station_anchor
	station_manager.station_area = $StationAnchor/StationArea
	enemy_spawner.actor_layer = actor_layer
	enemy_spawner.projectile_layer = projectile_layer
	enemy_spawner.activity_tracker = activity_tracker

	station_manager.deploy_finished.connect(_on_station_deploy_finished)
	station_manager.inbound_finished.connect(_on_station_inbound_finished)
	station_manager.dock_finished.connect(_on_station_dock_finished)
	station_manager.redeploy_finished.connect(_on_station_redeploy_finished)
	enemy_spawner.enemy_destroyed.connect(_on_enemy_destroyed)
	enemy_spawner.wave_spawned.connect(_on_wave_spawned)
	activity_tracker.activity_changed.connect(_on_activity_changed)
	activity_tracker.run_completed.connect(_on_run_completed)

	_begin_node_cycle()
	world_state_changed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		var root: GameRoot = get_parent() as GameRoot
		if root != null:
			root.return_to_menu()

# --- Node cycle ---

func _begin_node_cycle() -> void:
	_clear_runtime_objects()
	_read_map_node_params()
	node_state = NodeState.DEPLOYING
	asteroids_remaining = 0
	mission_message = "Station warping in..."
	station_manager.begin_deploy()
	_spawn_asteroids()
	world_state_changed.emit()

func _read_map_node_params() -> void:
	var map_node: NodeMapData.MapNode = null
	if GameData.instance != null and GameData.instance.node_map != null:
		map_node = GameData.instance.node_map.get_current_node()
	var cap: int = 2
	var asteroid_count: int = 7
	var danger: float = 0.3
	if map_node != null:
		cap = maxi(1, map_node.enemy_fleet_size)
		asteroid_count = map_node.asteroid_count
		danger = map_node.danger_level
	target_asteroid_count = asteroid_count
	enemy_spawner.reset(cap)
	activity_tracker.reset(danger)

func _clear_runtime_objects() -> void:
	for child in actor_layer.get_children():
		child.queue_free()
	for child in projectile_layer.get_children():
		child.queue_free()
	for child in pickup_layer.get_children():
		child.queue_free()
	player = null
	camera_rig.player = null
	enemy_spawner.player = null

# --- Spawning ---

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as PlayerShip
	player.global_position = station_anchor.global_position + Vector3(0.0, 0.25, 8.0)
	player.projectile_parent = projectile_layer
	player.world = self
	actor_layer.add_child(player)
	camera_rig.player = player
	enemy_spawner.player = player
	enemy_spawner.spawn_center = station_anchor.global_position

func _spawn_asteroids() -> void:
	var min_distance: float = 6.0
	var placed: Array[Vector3] = []
	for _i in range(target_asteroid_count):
		var spawn_position: Vector3 = Vector3.ZERO
		for _attempt in range(20):
			var angle: float = randf() * TAU
			var distance: float = randf_range(10.0, 28.0)
			spawn_position = Vector3(cos(angle) * distance, 1.0, sin(angle) * distance)
			var too_close: bool = false
			for existing in placed:
				if spawn_position.distance_to(existing) < min_distance:
					too_close = true
					break
			if not too_close:
				break
		placed.append(spawn_position)
		var asteroid: AsteroidNode = ASTEROID_SCENE.instantiate() as AsteroidNode
		asteroid.global_position = spawn_position
		asteroid.mined_out.connect(_on_asteroid_mined_out)
		actor_layer.add_child(asteroid)
		asteroids_remaining += 1

# --- Station interaction ---

func try_interact_at_station() -> bool:
	if node_state in [NodeState.DOCKING, NodeState.DOCKED]:
		return true
	if not station_manager.station_present:
		call_station_to_node()
		return false
	if not station_manager.is_player_in_range(player):
		mission_message = "Move closer to the station to dock."
		world_state_changed.emit()
		return false
	if GameData.instance == null:
		return false
	GameData.instance.repair_player_full()
	node_state = NodeState.DOCKING
	station_manager.begin_dock()
	mission_message = "Docking complete. Station spooling for departure."
	if player != null and is_instance_valid(player):
		player.visible = false
		player.process_mode = Node.PROCESS_MODE_DISABLED
	enemy_spawner.stop_spawning()
	activity_tracker.stop_tracking()
	world_state_changed.emit()
	return true

func call_station_to_node() -> void:
	if station_manager.station_present or node_state in [NodeState.STATION_INBOUND, NodeState.DOCKING, NodeState.DOCKED]:
		return
	node_state = NodeState.STATION_INBOUND
	station_manager.begin_inbound()
	mission_message = "Calling station in. Hold the node while it warps to your position."
	world_state_changed.emit()

func apply_station_damage(amount: int) -> void:
	station_manager.apply_damage(amount)
	if GameData.instance != null and GameData.instance.station_integrity <= 0:
		mission_message = "The station has fallen. Press Esc to return to the menu."
	world_state_changed.emit()

func redeploy_node() -> void:
	_begin_node_cycle()

func register_pickup(pickup: ResourcePickup) -> void:
	pickup_layer.add_child(pickup)

func get_activity_display() -> int:
	return activity_tracker.get_activity_display() if activity_tracker else 0

# --- Component signal handlers ---

func _on_station_deploy_finished() -> void:
	mission_message = "Station deployed. Launching player ship..."
	_spawn_player()
	node_state = NodeState.ACTIVE
	station_manager.depart_after_launch()
	enemy_spawner.start_spawning()
	activity_tracker.start_tracking()
	mission_message = "Node live. The station has warped clear. Mine fast, make noise, and call it back when you want out."
	world_state_changed.emit()

func _on_station_inbound_finished() -> void:
	node_state = NodeState.ACTIVE
	mission_message = "Station on-site. Move close and press F to dock."
	world_state_changed.emit()

func _on_station_dock_finished() -> void:
	node_state = NodeState.DOCKED
	mission_message = "Docking complete. Node map ready."
	world_state_changed.emit()
	dock_sequence_finished.emit()

func _on_station_redeploy_finished() -> void:
	node_state = NodeState.ACTIVE
	mission_message = "Fresh node deployment complete. Get back out there."
	world_state_changed.emit()

func _on_enemy_destroyed(_enemy: EnemyShip) -> void:
	activity_tracker.add_activity(2.0)
	mission_message = "Hostile down. Node heat is still climbing."
	_check_win_condition()
	world_state_changed.emit()

func _on_wave_spawned() -> void:
	mission_message = "Node activity rising. Hostiles inbound."
	world_state_changed.emit()

func _on_asteroid_mined_out() -> void:
	asteroids_remaining = maxi(0, asteroids_remaining - 1)
	activity_tracker.add_activity(5.0)
	mission_message = "Ore cracked loose. That definitely made some noise."
	_check_win_condition()
	world_state_changed.emit()

func _on_activity_changed() -> void:
	_check_win_condition()
	world_state_changed.emit()

func _on_run_completed() -> void:
	mission_message = "Node pressure broken. Call the station and dock out."
	if GameData.instance != null:
		GameData.instance.cleared_runs += 1
		if GameData.instance.node_map != null:
			var current: NodeMapData.MapNode = GameData.instance.node_map.get_current_node()
			if current != null:
				current.is_cleared = true
	world_state_changed.emit()

func _check_win_condition() -> void:
	activity_tracker.check_win_condition(enemy_spawner.enemies_remaining)
