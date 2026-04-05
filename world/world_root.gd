extends Node3D
class_name WorldRoot

signal world_state_changed

const PLAYER_SCENE: PackedScene = preload("res://world/player/player_ship.tscn")
const ENEMY_SCENE: PackedScene = preload("res://world/enemies/enemy_ship.tscn")
const ASTEROID_SCENE: PackedScene = preload("res://world/props/asteroid_node.tscn")

enum NodeState {
	DEPLOYING,
	ACTIVE,
	STATION_INBOUND,
	DOCKED,
	REDEPLOYING
}

@onready var actor_layer: Node3D = $Actors
@onready var projectile_layer: Node3D = $Projectiles
@onready var pickup_layer: Node3D = $Pickups
@onready var station_anchor: Node3D = $StationAnchor
@onready var station_area: Area3D = $StationAnchor/StationArea
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D

var player: PlayerShip = null
var enemies_remaining: int = 0
var asteroids_remaining: int = 0
var run_complete: bool = false
var mission_message: String = "Deploying frontier station..."

var node_state: NodeState = NodeState.DEPLOYING
var station_present: bool = false
var station_transition_timer: float = 0.0
var station_transition_duration: float = 1.2
var station_deploy_scale: float = 0.0
var station_pending_spawn_player: bool = false

var activity: float = 0.0
var time_in_node: float = 0.0
var spawn_timer: float = 20.0
var spawn_cap_base: int = 2

func _ready() -> void:
	add_to_group("world_root")
	station_anchor.visible = false
	station_area.monitoring = false
	_begin_node_cycle()
	world_state_changed.emit()

func _process(delta: float) -> void:
	_update_camera()
	_update_station_transition(delta)
	if node_state == NodeState.ACTIVE:
		_update_activity(delta)
		_update_enemy_spawning(delta)
	if not run_complete and enemies_remaining <= 0 and activity >= 35.0:
		run_complete = true
		mission_message = "Node pressure broken. Call the station and dock out."
		if GameData.instance != null:
			GameData.instance.cleared_runs += 1
		world_state_changed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		var root: GameRoot = get_parent() as GameRoot
		if root != null:
			root.return_to_menu()

func _update_camera() -> void:
	if player != null and is_instance_valid(player):
		camera_rig.global_position.x = player.global_position.x
		camera_rig.global_position.z = player.global_position.z
	else:
		camera_rig.global_position.x = lerp(camera_rig.global_position.x, station_anchor.global_position.x, 0.08)
		camera_rig.global_position.z = lerp(camera_rig.global_position.z, station_anchor.global_position.z + 4.0, 0.08)

func _begin_node_cycle() -> void:
	_clear_runtime_objects()
	node_state = NodeState.DEPLOYING
	station_transition_timer = 0.0
	station_deploy_scale = 0.0
	station_pending_spawn_player = true
	station_present = true
	station_anchor.visible = true
	station_anchor.scale = Vector3.ONE * 0.01
	station_area.monitoring = false
	enemies_remaining = 0
	asteroids_remaining = 0
	activity = 0.0
	time_in_node = 0.0
	spawn_timer = 3.5
	run_complete = false
	mission_message = "Station warping in..."
	_spawn_asteroids()
	world_state_changed.emit()

func _clear_runtime_objects() -> void:
	for child in actor_layer.get_children():
		child.queue_free()
	for child in projectile_layer.get_children():
		child.queue_free()
	for child in pickup_layer.get_children():
		child.queue_free()
	player = null

func _update_station_transition(delta: float) -> void:
	if node_state != NodeState.DEPLOYING and node_state != NodeState.STATION_INBOUND and node_state != NodeState.REDEPLOYING:
		return
	station_transition_timer += delta
	var t: float = clampf(station_transition_timer / station_transition_duration, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - t, 3.0)
	station_anchor.scale = Vector3.ONE * maxf(0.01, eased)
	if t < 1.0:
		return
	station_anchor.scale = Vector3.ONE
	station_area.monitoring = true
	if node_state == NodeState.DEPLOYING:
		mission_message = "Station deployed. Launching player ship..."
		if station_pending_spawn_player:
			_spawn_player()
			station_pending_spawn_player = false
		node_state = NodeState.ACTIVE
		_station_depart_after_launch()
		mission_message = "Node live. The station has warped clear. Mine fast, make noise, and call it back when you want out."
		world_state_changed.emit()
	elif node_state == NodeState.STATION_INBOUND:
		node_state = NodeState.ACTIVE
		mission_message = "Station on-site. Move close and press F to dock."
		world_state_changed.emit()
	elif node_state == NodeState.REDEPLOYING:
		node_state = NodeState.ACTIVE
		mission_message = "Fresh node deployment complete. Get back out there."
		world_state_changed.emit()

func _update_activity(delta: float) -> void:
	time_in_node += delta
	activity += (0.55 + (time_in_node * 0.055)) * delta
	world_state_changed.emit()

func _update_enemy_spawning(delta: float) -> void:
	spawn_timer -= delta
	var live_cap: int = spawn_cap_base + int(floor(activity / 18.0))
	live_cap = mini(live_cap, 8)
	if spawn_timer > 0.0 or enemies_remaining >= live_cap:
		return
	_spawn_enemy_wave()
	var next_interval: float = maxf(0.8, 4.5 - (activity * 0.08))
	spawn_timer = randf_range(next_interval * 0.8, next_interval * 1.2)


func _station_depart_after_launch() -> void:
	station_present = false
	station_anchor.visible = false
	station_area.monitoring = false
	station_anchor.scale = Vector3.ONE

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as PlayerShip
	player.global_position = station_anchor.global_position + Vector3(0.0, 0.25, 8.0)
	player.projectile_parent = projectile_layer
	player.world = self
	actor_layer.add_child(player)

func _spawn_enemy_wave() -> void:
	var wave_size: int = 1 + int(floor(activity / 28.0))
	wave_size = mini(wave_size, 3)
	for index in range(wave_size):
		var enemy: EnemyShip = ENEMY_SCENE.instantiate() as EnemyShip
		var angle: float = randf() * TAU
		var distance: float = randf_range(24.0, 34.0)
		var spawn_position: Vector3 = station_anchor.global_position + Vector3(cos(angle) * distance, 1.25, sin(angle) * distance)
		enemy.global_position = spawn_position
		enemy.target = player
		enemy.projectile_parent = projectile_layer
		enemy.destroyed.connect(_on_enemy_destroyed)
		actor_layer.add_child(enemy)
		enemies_remaining += 1
	mission_message = "Node activity rising. Hostiles inbound."
	world_state_changed.emit()

func _spawn_asteroids() -> void:
	var asteroid_positions: Array[Vector3] = [
		Vector3(14.0, 1.0, 12.0),
		Vector3(19.0, 1.0, 4.0),
		Vector3(-16.0, 1.0, 8.0),
		Vector3(-10.0, 1.0, -12.0),
		Vector3(8.0, 1.0, -18.0),
		Vector3(24.0, 1.0, -6.0),
		Vector3(-22.0, 1.0, 20.0)
	]
	for spawn_position in asteroid_positions:
		var asteroid: AsteroidNode = ASTEROID_SCENE.instantiate() as AsteroidNode
		asteroid.global_position = spawn_position
		asteroid.mined_out.connect(_on_asteroid_mined_out)
		actor_layer.add_child(asteroid)
		asteroids_remaining += 1

func is_player_in_station_range() -> bool:
	if not station_present:
		return false
	if player == null or not is_instance_valid(player):
		return false
	var overlapping_bodies: Array[Node3D] = station_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body == player:
			return true
	return false

func try_interact_at_station() -> bool:
	if node_state == NodeState.DOCKED:
		return true
	if not station_present:
		call_station_to_node()
		return false
	if not is_player_in_station_range():
		mission_message = "Move closer to the station to dock."
		world_state_changed.emit()
		return false
	if GameData.instance == null:
		return false
		
	GameData.instance.repair_player_full()
	node_state = NodeState.DOCKED
	mission_message = "Docking complete. Open the map panel and redeploy when ready."
	if player != null and is_instance_valid(player):
		player.visible = false
		player.process_mode = Node.PROCESS_MODE_DISABLED
	world_state_changed.emit()
	return true

func call_station_to_node() -> void:
	if station_present or node_state == NodeState.STATION_INBOUND or node_state == NodeState.DOCKED:
		return
	station_present = true
	station_anchor.visible = true
	station_anchor.scale = Vector3.ONE * 0.01
	station_transition_timer = 0.0
	station_area.monitoring = false
	node_state = NodeState.STATION_INBOUND
	mission_message = "Calling station in. Hold the node while it warps to your position."
	world_state_changed.emit()

func redeploy_node() -> void:
	_begin_node_cycle()

func apply_station_damage(amount: int) -> void:
	if not station_present:
		return
	if GameData.instance == null:
		return
	GameData.instance.station_integrity = maxi(0, GameData.instance.station_integrity - amount)
	if GameData.instance.station_integrity <= 0:
		mission_message = "The station has fallen. Press Esc to return to the menu."
	world_state_changed.emit()

func _on_enemy_destroyed(enemy: EnemyShip) -> void:
	enemies_remaining = maxi(0, enemies_remaining - 1)
	activity += 2.0
	mission_message = "Hostile down. Node heat is still climbing."
	world_state_changed.emit()

func _on_asteroid_mined_out() -> void:
	asteroids_remaining = maxi(0, asteroids_remaining - 1)
	activity += 5.0
	mission_message = "Ore cracked loose. That definitely made some noise."
	world_state_changed.emit()

func register_pickup(pickup: ResourcePickup) -> void:
	pickup_layer.add_child(pickup)

func get_activity_display() -> int:
	return int(round(activity))
