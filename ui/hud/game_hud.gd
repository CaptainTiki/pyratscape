extends Control
class_name GameHud

var world: WorldRoot = null

@onready var hull_label: Label = %HullLabel
@onready var resources_label: Label = %ResourcesLabel
@onready var mission_label: Label = %MissionLabel
@onready var sector_label: Label = %SectorLabel

func bind_world(new_world: Node3D) -> void:
	world = new_world as WorldRoot
	if world != null:
		world.world_state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if GameData.instance == null:
		return
	hull_label.text = "Hull: %s / %s\nStation: %s" % [str(GameData.instance.player_hull), str(GameData.instance.player_max_hull), str(GameData.instance.station_integrity)]
	resources_label.text = "Scrap: %s\nCrystals: %s\nEnemies: %s\nAsteroids: %s\nActivity: %s" % [str(GameData.instance.scrap), str(GameData.instance.crystals), str(_get_enemy_count()), str(_get_asteroid_count()), str(_get_activity())]
	if world != null:
		mission_label.text = world.mission_message
		sector_label.text = _get_sector_state_text()
		visible = world.sector_state != WorldRoot.SectorState.DOCKED

func _get_enemy_count() -> int:
	return 0 if world == null else world.enemies_remaining

func _get_asteroid_count() -> int:
	return 0 if world == null else world.asteroids_remaining

func _get_activity() -> int:
	return 0 if world == null else world.get_activity_display()

func _get_sector_state_text() -> String:
	if world == null:
		return "Sector Status: --"
	match world.sector_state:
		WorldRoot.SectorState.DEPLOYING:
			return "Sector Status: Station deploying"
		WorldRoot.SectorState.ACTIVE:
			return "Sector Status: Active field ops"
		WorldRoot.SectorState.STATION_INBOUND:
			return "Sector Status: Station inbound"
		WorldRoot.SectorState.DOCKING:
			return "Sector Status: Docking"
		WorldRoot.SectorState.DOCKED:
			return "Sector Status: Docked"
		WorldRoot.SectorState.REDEPLOYING:
			return "Sector Status: Redeploying"
		_:
			return "Sector Status: Unknown"
