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

func _ready() -> void:
	add_to_group("world_root")
	camera_rig.follow_target = station_anchor
	station_manager.station_anchor = station_anchor
	station_manager.station_area = $StationAnchor/StationArea
	enemy_spawner.actor_layer = actor_layer
	enemy_spawner.projectile_layer = projectile_layer
	enemy_spawner.activity_tracker = activity_tracker
	sector_controller.setup(self)
	sector_controller.sector_changed.connect(func() -> void: world_state_changed.emit())
	sector_controller.begin_sector_cycle()
	world_state_changed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		var root: GameRoot = get_parent() as GameRoot
		if root != null:
			root.toggle_pause()
