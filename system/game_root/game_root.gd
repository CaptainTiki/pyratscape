extends Node3D
class_name GameRoot

@onready var world: Node3D = $World
@onready var hud: GameHud = $CanvasLayer/GameHUD

func _ready() -> void:
	hud.bind_world(world)

func return_to_menu() -> void:
	var main: Main = get_tree().current_scene as Main
	if main != null:
		main.return_to_main_menu()
