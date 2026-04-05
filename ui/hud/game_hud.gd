extends Control
class_name GameHud

var world: WorldRoot = null

@onready var hull_label: Label = %HullLabel
@onready var resources_label: Label = %ResourcesLabel
@onready var mission_label: Label = %MissionLabel
@onready var upgrades_panel: PanelContainer = %UpgradesPanel
@onready var map_panel: PanelContainer = %MapPanel
@onready var node_label: Label = %NodeLabel

func _ready() -> void:
	upgrades_panel.hide()
	map_panel.hide()

func bind_world(new_world: Node3D) -> void:
	world = new_world as WorldRoot
	if world != null:
		world.world_state_changed.connect(_refresh)
	_refresh()

func _process(_delta: float) -> void:
	_refresh()
	if world == null:
		return
	if Input.is_action_just_pressed("interact") and world.node_state == WorldRoot.NodeState.DOCKED:
		map_panel.visible = not map_panel.visible
		upgrades_panel.visible = map_panel.visible

func _refresh() -> void:
	if GameData.instance == null:
		return
	hull_label.text = "Hull: %s / %s\nStation: %s" % [str(GameData.instance.player_hull), str(GameData.instance.player_max_hull), str(GameData.instance.station_integrity)]
	resources_label.text = "Scrap: %s\nCrystals: %s\nEnemies: %s\nAsteroids: %s\nActivity: %s" % [str(GameData.instance.scrap), str(GameData.instance.crystals), str(_get_enemy_count()), str(_get_asteroid_count()), str(_get_activity())]
	if world != null:
		mission_label.text = world.mission_message
		node_label.text = _get_node_state_text()
		if world.node_state != WorldRoot.NodeState.DOCKED:
			map_panel.hide()
			upgrades_panel.hide()

func _get_enemy_count() -> int:
	if world == null:
		return 0
	return world.enemies_remaining

func _get_asteroid_count() -> int:
	if world == null:
		return 0
	return world.asteroids_remaining

func _get_activity() -> int:
	if world == null:
		return 0
	return world.get_activity_display()

func _get_node_state_text() -> String:
	if world == null:
		return "Node Status: --"
	match world.node_state:
		WorldRoot.NodeState.DEPLOYING:
			return "Node Status: Station deploying"
		WorldRoot.NodeState.ACTIVE:
			return "Node Status: Active field ops"
		WorldRoot.NodeState.STATION_INBOUND:
			return "Node Status: Station inbound"
		WorldRoot.NodeState.DOCKED:
			return "Node Status: Docked"
		WorldRoot.NodeState.REDEPLOYING:
			return "Node Status: Redeploying"
		_:
			return "Node Status: Unknown"

func _on_upgrade_damage_button_pressed() -> void:
	if GameData.instance != null and GameData.instance.buy_damage_upgrade():
		_apply_upgrades_to_player()

func _on_upgrade_rate_button_pressed() -> void:
	if GameData.instance != null and GameData.instance.buy_fire_rate_upgrade():
		_apply_upgrades_to_player()

func _on_upgrade_hull_button_pressed() -> void:
	if GameData.instance != null and GameData.instance.buy_hull_upgrade():
		_apply_upgrades_to_player()

func _on_upgrade_mining_button_pressed() -> void:
	if GameData.instance != null and GameData.instance.buy_mining_upgrade():
		_apply_upgrades_to_player()

func _apply_upgrades_to_player() -> void:
	if world == null or world.player == null or not is_instance_valid(world.player):
		return
	world.player._sync_from_game_data()
	_refresh()

func _on_redeploy_button_pressed() -> void:
	if world != null:
		map_panel.hide()
		upgrades_panel.hide()
		world.redeploy_node()
