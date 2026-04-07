extends Control
class_name Hud

const CARGO_MAX: float = 50.0

var world: WorldRoot = null
var _connected_player: PlayerShip = null

@onready var hull_bar: ProgressBar = %HullBar
@onready var power_bar: ProgressBar = %PowerBar
@onready var cargo_bar: ProgressBar = %CargoBar
@onready var missile_label: Label = %MissileLabel
@onready var station_status_label: Label = %StationStatusLabel
@onready var docking_label: Label = %DockingLabel
@onready var scrap_bar: ProgressBar = %ScrapBar
@onready var crystal_bar: ProgressBar = %CrystalBar
@onready var minimap: MinimapDisplay = %MinimapDisplay
@onready var damage_flash: ColorRect = $DamageFlash

func bind_world(new_world: Node3D) -> void:
	world = new_world as WorldRoot
	if world != null:
		world.world_state_changed.connect(_refresh)
	minimap.world = world
	_refresh()

func _refresh() -> void:
	_try_connect_player_damage()
	if GameData.instance == null:
		return
	_refresh_ship()
	if world != null:
		_refresh_station()
		visible = world.sector_controller.sector_state != SectorController.SectorState.DOCKED

func _refresh_ship() -> void:
	hull_bar.max_value = GameData.instance.player_max_hull
	hull_bar.value = GameData.instance.player_hull
	power_bar.value = 100.0  # placeholder until power system is implemented
	cargo_bar.value = minf(GameData.instance.scrap + GameData.instance.crystals, CARGO_MAX)
	missile_label.text = "MSSL  --"  # placeholder until ammo system is implemented

func _refresh_station() -> void:
	var state: SectorController.SectorState = world.sector_controller.sector_state
	station_status_label.text = _get_station_text(state)
	docking_label.text = _get_docking_text(state)
	scrap_bar.value = minf(GameData.instance.scrap, 100.0)
	crystal_bar.value = minf(GameData.instance.crystals, 100.0)

func _get_station_text(state: SectorController.SectorState) -> String:
	match state:
		SectorController.SectorState.DEPLOYING:
			return "STA  WARP"
		SectorController.SectorState.ACTIVE, SectorController.SectorState.STATION_INBOUND:
			return "STA  LIVE"
		SectorController.SectorState.DOCKING, SectorController.SectorState.DOCKED:
			return "STA  DOCK"
		SectorController.SectorState.REDEPLOYING:
			return "STA  MOVE"
		_:
			return "STA  --"

func _get_docking_text(state: SectorController.SectorState) -> String:
	match state:
		SectorController.SectorState.ACTIVE:
			return "DOCK  [F]"
		SectorController.SectorState.STATION_INBOUND:
			return "DOCK  IN"
		SectorController.SectorState.DOCKING:
			return "DOCK  ACT"
		_:
			return "DOCK  --"

func _try_connect_player_damage() -> void:
	if world == null:
		return
	var player: PlayerShip = world.sector_controller.player
	if player == null or not is_instance_valid(player):
		_connected_player = null
		return
	if player == _connected_player:
		return
	_connected_player = player
	player.hull_component.damaged.connect(_on_player_damaged)

func _on_player_damaged() -> void:
	damage_flash.color.a = 0.3
	var tween := create_tween()
	tween.tween_property(damage_flash, "color:a", 0.0, 0.4)
