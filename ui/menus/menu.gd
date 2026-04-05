extends Control
class_name Menu

enum Type {MAIN, STATION, NODE_MAP, PAUSE}

var manager: MenuManager = null
var data: GameData = null

func _ready() -> void:
	manager = MenuManager.instance

func show_menu() -> void:
	set_process(true)
	show()

func hide_menu() -> void:
	set_process(false)
	hide()

func setup_menu() -> void:
	data = GameData.instance
