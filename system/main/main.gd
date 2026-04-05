extends Node3D
class_name Main

@onready var menu_manager: MenuManager = %MenuManager

var game_root: Node = null

func _ready() -> void:
	menu_manager.show_menu(Menu.Type.MAIN)

func start_game() -> void:
	if game_root != null:
		game_root.queue_free()
		game_root = null
	game_root = Prefabs.game_root_scene.instantiate()
	add_child(game_root)
	move_child(game_root, 0)
	menu_manager.hide_current_menu()

func return_to_main_menu() -> void:
	if game_root != null:
		game_root.queue_free()
		game_root = null
	menu_manager.show_menu(Menu.Type.MAIN)
