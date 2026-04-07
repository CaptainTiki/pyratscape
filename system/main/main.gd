extends Node3D
class_name Main

@onready var menu_manager: MenuManager = %MenuManager

var game_root: GameRoot = null

func _ready() -> void:
	menu_manager.show_menu(Menu.Type.MAIN)

func start_game() -> void:
	if game_root != null:
		game_root.queue_free()
		game_root = null
	game_root = Prefabs.game_root_scene.instantiate() as GameRoot
	add_child(game_root)
	move_child(game_root, 0)
	menu_manager.hide_current_menu()

func return_to_main_menu() -> void:
	get_tree().paused = false
	menu_manager.show_menu(Menu.Type.MAIN)
	if game_root != null:
		game_root.queue_free()
		game_root = null

func show_pause_menu() -> void:
	menu_manager.show_menu(Menu.Type.PAUSE)

func resume_from_pause() -> void:
	get_tree().paused = false
	menu_manager.hide_current_menu()

func show_docking_bay_menu() -> void:
	menu_manager.show_menu(Menu.Type.DOCKING_BAY)

func show_station_menu() -> void:
	menu_manager.show_menu(Menu.Type.STATION)

func redeploy_current_game() -> void:
	if game_root == null:
		start_game()
		return
	menu_manager.hide_current_menu()
	game_root.world.sector_controller.redeploy_sector()
	game_root.fade_from_black()
