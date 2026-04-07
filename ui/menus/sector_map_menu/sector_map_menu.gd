extends Menu
class_name SectorMapMenu

@onready var sector_map_control: SectorMap = %SectorMapControl
@onready var sector_info_label: Label = %SectorInfoLabel
@onready var deploy_button: Button = %DeployButton

func _ready() -> void:
	super._ready()
	if sector_map_control != null:
		sector_map_control.sector_selected.connect(_on_sector_map_sector_selected)
	if deploy_button != null:
		deploy_button.disabled = true

func show_menu() -> void:
	super.show_menu()
	if deploy_button != null:
		deploy_button.disabled = true
	if sector_info_label != null:
		sector_info_label.text = "Select a connected sector to deploy."
	if sector_map_control != null and GameData.instance != null and GameData.instance.sector_map != null:
		sector_map_control.set_map_data(GameData.instance.sector_map)

func _on_sector_map_sector_selected(sector_id: int) -> void:
	if GameData.instance == null or GameData.instance.sector_map == null:
		return
	var sector: SectorMapData.SectorData = GameData.instance.sector_map.get_sector_by_id(sector_id)
	if sector == null:
		return
	if deploy_button != null:
		deploy_button.disabled = false
	var danger_text: String = "Low"
	if sector.danger_level > 0.6:
		danger_text = "High"
	elif sector.danger_level > 0.3:
		danger_text = "Medium"

	var enemy_count: int = 0
	if GameData.instance != null and GameData.instance.enemy_forces != null:
		enemy_count = GameData.instance.enemy_forces.get_enemies_in_sector(sector_id)

	var info: String = "Fleet: %d ships  |  Asteroids: %d  |  Danger: %s" % [enemy_count, sector.asteroid_count, danger_text]
	if sector.has_poi:
		info += "  |  POI detected"
	if sector_info_label != null:
		sector_info_label.text = info

func _on_deploy_button_pressed() -> void:
	if GameData.instance != null and GameData.instance.sector_map != null:
		var selected: SectorMapData.SectorData = GameData.instance.sector_map.get_selected_sector()
		if selected == null:
			return
		GameData.instance.sector_map.set_current_sector(selected.id)
		GameData.instance.sector_map.shuffle_enemy_fleets()
		GameData.instance.sector_map.selected_sector_id = -1
	var main: Main = get_tree().current_scene as Main
	if main != null:
		main.redeploy_current_game()

func _on_back_button_pressed() -> void:
	if manager != null:
		manager.show_menu(Menu.Type.STATION)
