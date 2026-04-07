extends Menu
class_name DockingBayMenu

@onready var bay1_health_label: Label = %Bay1HealthLabel
@onready var research_label: Label = %ResearchLabel
@onready var production_label: Label = %ProductionLabel

func show_menu() -> void:
	super.show_menu()
	_refresh()

func _refresh() -> void:
	if GameData.instance == null:
		return
	var gd := GameData.instance
	bay1_health_label.text = "HP  %d / %d" % [gd.player_hull, gd.player_ship_max_hull]
	research_label.text = "RESEARCH    --"
	production_label.text = "PRODUCTION  --"

func _on_deploy_bay1_pressed() -> void:
	var main := get_tree().current_scene as Main
	if main != null:
		main.redeploy_current_game()

func _on_activate_jump_pressed() -> void:
	if manager != null:
		manager.show_menu(Menu.Type.STATION)
