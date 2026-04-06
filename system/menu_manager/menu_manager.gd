extends Control
class_name MenuManager

static var instance : MenuManager

var menus : Dictionary[Menu.Type, Menu] = {}
var current_menu: Menu = null

func _ready() -> void:
	instance = self
	init_menus()

func show_menu(menu_type: Menu.Type) -> void:
	if current_menu != null:
		current_menu.hide_menu()
	menus[menu_type].show_menu()
	current_menu = menus[menu_type]

func hide_current_menu() -> void:
	if current_menu != null:
		current_menu.hide_menu()
		current_menu = null

func set_menu_data() -> void:
	for menu in menus:
		menus[menu].setup_menu()

func init_menus() -> void:
	_add_menu(Menu.Type.MAIN, Prefabs.main_menu_scene)
	_add_menu(Menu.Type.STATION, Prefabs.station_menu_scene)
	_add_menu(Menu.Type.SECTOR_MAP, Prefabs.sector_map_menu_scene)

func _add_menu(type: Menu.Type, scene: PackedScene) -> void:
	var menu: Menu = scene.instantiate()
	menus[type] = menu
	add_child(menu)
	menu.hide_menu()
