extends Menu
class_name StationMenu

@onready var resources_label: Label = %ResourcesLabel
@onready var hull_label: Label = %HullLabel
@onready var damage_button: Button = %UpgradeDamageButton
@onready var rate_button: Button = %UpgradeRateButton
@onready var hull_button: Button = %UpgradeHullButton
@onready var mining_button: Button = %UpgradeMiningButton

func _ready() -> void:
	super._ready()

func show_menu() -> void:
	super.show_menu()
	_refresh()

func _refresh() -> void:
	if GameData.instance == null:
		return
	var gd: GameData = GameData.instance
	resources_label.text = "Scrap: %d  |  Crystals: %d" % [gd.scrap, gd.crystals]
	hull_label.text = "Hull: %d / %d  |  Station: %d%%" % [gd.player_hull, gd.player_max_hull, gd.station_integrity]
	var runs: int = gd.cleared_runs
	damage_button.text = "Upgrade Damage (%d Scrap)" % (20 + runs * 4)
	rate_button.text = "Upgrade Fire Rate (%d Scrap, 1 Crystal)" % (25 + runs * 5)
	hull_button.text = "Upgrade Hull (%d Scrap)" % (18 + runs * 4)
	mining_button.text = "Upgrade Mining (%d Scrap)" % (15 + runs * 3)

func _on_upgrade_damage_button_pressed() -> void:
	if GameData.instance != null and GameData.instance.buy_damage_upgrade():
		_apply_upgrades()

func _on_upgrade_rate_button_pressed() -> void:
	if GameData.instance != null and GameData.instance.buy_fire_rate_upgrade():
		_apply_upgrades()

func _on_upgrade_hull_button_pressed() -> void:
	if GameData.instance != null and GameData.instance.buy_hull_upgrade():
		_apply_upgrades()

func _on_upgrade_mining_button_pressed() -> void:
	if GameData.instance != null and GameData.instance.buy_mining_upgrade():
		_apply_upgrades()

func _apply_upgrades() -> void:
	var main: Main = get_tree().current_scene as Main
	if main != null and main.game_root != null:
		var world: WorldRoot = main.game_root.world
		if world != null and world.player != null and is_instance_valid(world.player):
			world.player._sync_from_game_data()
	_refresh()

func _on_node_map_button_pressed() -> void:
	if manager != null:
		manager.show_menu(Menu.Type.NODE_MAP)

func _on_redeploy_button_pressed() -> void:
	var main: Main = get_tree().current_scene as Main
	if main != null:
		main.redeploy_current_game()
