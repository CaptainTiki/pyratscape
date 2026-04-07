extends Node3D
class_name WorldRoot

signal world_state_changed

@onready var actor_layer: Node3D = $Actors
@onready var projectile_layer: Node3D = $Projectiles
@onready var pickup_layer: Node3D = $Pickups
@onready var station_anchor: StaticBody3D = $StationAnchor
@onready var camera_rig: CameraRig = $CameraRig
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var activity_tracker: ActivityTracker = $ActivityTracker
@onready var station_manager: StationManager = $StationManager
@onready var sector_controller: SectorController = $SectorController

var world_simulation: WorldSimulation = null

func _ready() -> void:
	add_to_group("world_root")
	camera_rig.follow_target = station_anchor
	station_manager.station_anchor = station_anchor
	station_manager.station_area = $StationAnchor/StationArea
	# Create and initialize world simulation first
	world_simulation = WorldSimulation.new()
	world_simulation.name = "WorldSimulation"
	add_child(world_simulation)
	if GameData.instance != null:
		var player_start_id := 0
		if GameData.instance.static_world != null:
			player_start_id = GameData.instance.static_world.get_player_start_id()
		world_simulation.initialize(
			GameData.instance.enemy_forces,
			GameData.instance.sector_map,
			player_start_id,
			GameData.instance.static_world,
		)
		world_simulation.forced_deploy_required.connect(_on_forced_deploy_required)

	# Now set up spawner with simulation awareness
	enemy_spawner.actor_layer = actor_layer
	enemy_spawner.projectile_layer = projectile_layer
	enemy_spawner.activity_tracker = activity_tracker
	enemy_spawner.world_simulation = world_simulation
	if GameData.instance != null:
		enemy_spawner.enemy_forces = GameData.instance.enemy_forces

	sector_controller.setup(self)
	sector_controller.sector_changed.connect(func() -> void: world_state_changed.emit())

	sector_controller.begin_sector_cycle()
	world_state_changed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		var root: GameRoot = get_parent() as GameRoot
		if root != null:
			root.toggle_pause()

func _on_forced_deploy_required() -> void:
	# Enemy accumulation has triggered a forced deployment
	if sector_controller != null:
		sector_controller.call_station_to_sector()
