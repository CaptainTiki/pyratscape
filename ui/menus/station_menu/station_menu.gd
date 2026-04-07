extends Menu
class_name StationMenu

@onready var resources_label: Label = %ResourcesLabel
@onready var hull_label: Label = %HullLabel

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

func _on_sector_map_button_pressed() -> void:
	if manager != null:
		manager.show_menu(Menu.Type.SECTOR_MAP)

func _on_redeploy_button_pressed() -> void:
	var main: Main = get_tree().current_scene as Main
	if main != null:
		main.redeploy_current_game()

func _on_hangar_button_pressed() -> void:
	if manager != null:
		manager.show_menu(Menu.Type.HANGAR)

func _on_production_button_pressed() -> void:
	if manager != null:
		manager.show_menu(Menu.Type.PRODUCTION)

func _on_research_button_pressed() -> void:
	if manager != null:
		manager.show_menu(Menu.Type.RESEARCH)
