extends Menu
class_name NodeMapMenu

@onready var node_map_control: NodeMap = %NodeMapControl
@onready var node_info_label: Label = %NodeInfoLabel
@onready var deploy_button: Button = %DeployButton

func _ready() -> void:
	super._ready()
	if node_map_control != null:
		node_map_control.node_selected.connect(_on_node_map_node_selected)
	if deploy_button != null:
		deploy_button.disabled = true

func show_menu() -> void:
	super.show_menu()
	if deploy_button != null:
		deploy_button.disabled = true
	if node_info_label != null:
		node_info_label.text = "Select a connected node to deploy."
	if node_map_control != null and GameData.instance != null and GameData.instance.node_map != null:
		node_map_control.set_map_data(GameData.instance.node_map)

func _on_node_map_node_selected(node_id: int) -> void:
	if GameData.instance == null or GameData.instance.node_map == null:
		return
	var node: NodeMapData.MapNode = GameData.instance.node_map.get_node_by_id(node_id)
	if node == null:
		return
	if deploy_button != null:
		deploy_button.disabled = false
	var danger_text: String = "Low"
	if node.danger_level > 0.6:
		danger_text = "High"
	elif node.danger_level > 0.3:
		danger_text = "Medium"
	var info: String = "Fleet: %d ships  |  Asteroids: %d  |  Danger: %s" % [node.enemy_fleet_size, node.asteroid_count, danger_text]
	if node.has_poi:
		info += "  |  POI detected"
	if node_info_label != null:
		node_info_label.text = info

func _on_deploy_button_pressed() -> void:
	if GameData.instance != null and GameData.instance.node_map != null:
		var selected: NodeMapData.MapNode = GameData.instance.node_map.get_selected_node()
		if selected == null:
			return
		GameData.instance.node_map.set_current_node(selected.id)
		GameData.instance.node_map.shuffle_enemy_fleets()
		GameData.instance.node_map.selected_node_id = -1
	var main: Main = get_tree().current_scene as Main
	if main != null:
		main.redeploy_current_game()

func _on_back_button_pressed() -> void:
	if manager != null:
		manager.show_menu(Menu.Type.STATION)
