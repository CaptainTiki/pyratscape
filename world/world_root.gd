extends Node3D
class_name WorldRoot

signal world_state_changed
signal dock_sequence_finished

enum SectorState {
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
@onready var sector_controller: SectorController = $SectorController

var player: PlayerShip:
	get: return sector_controller.player if sector_controller else null
var asteroids_remaining: int:
	get: return sector_controller.asteroids_remaining if sector_controller else 0
var sector_state: int:
	get: return sector_controller.sector_state if sector_controller else SectorState.DEPLOYING
var mission_message: String:
	get: return sector_controller.mission_message if sector_controller else "Deploying frontier station..."
	set(value):
		if sector_controller != null:
			sector_controller.mission_message = value
var target_asteroid_count: int:
	get: return sector_controller.target_asteroid_count if sector_controller else 0
var enemies_remaining: int:
	get: return sector_controller.enemies_remaining if sector_controller else 0
var activity: float:
	get: return sector_controller.activity if sector_controller else 0.0
var run_complete: bool:
	get: return sector_controller.run_complete if sector_controller else false

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
	sector_controller.dock_sequence_finished.connect(func() -> void: dock_sequence_finished.emit())
	sector_controller.begin_sector_cycle()
	world_state_changed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		var root: GameRoot = get_parent() as GameRoot
		if root != null:
			root.return_to_menu()

func try_interact_at_station() -> bool:
	return sector_controller.try_interact_at_station()

func call_station_to_sector() -> void:
	sector_controller.call_station_to_sector()

func apply_station_damage(amount: int) -> void:
	sector_controller.apply_station_damage(amount)

func redeploy_sector() -> void:
	sector_controller.redeploy_sector()

func register_pickup(pickup: ResourcePickup) -> void:
	sector_controller.register_pickup(pickup)

func get_activity_display() -> int:
	return sector_controller.get_activity_display()
