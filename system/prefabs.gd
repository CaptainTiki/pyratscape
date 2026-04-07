extends RefCounted
class_name Prefabs

# when adding new - use paths, if godot has not generated a UID yet.
# do not use \ switches

static var main_menu_scene: PackedScene = load("uid://djdvv5hs7iv0")
static var station_menu_scene: PackedScene = load("res://ui/menus/station_menu/station_menu.tscn")
static var sector_map_menu_scene: PackedScene = load("res://ui/menus/sector_map_menu/sector_map_menu.tscn")

static var docking_bay_menu_scene: PackedScene = load("res://ui/menus/docking_bay_menu/docking_bay_menu.tscn")
static var pause_menu_scene: PackedScene = load("res://ui/menus/pause_menu/pause_menu.tscn")

static var game_root_scene: PackedScene = load("uid://deslccio18fh1")
static var hangar_menu_scene: PackedScene = load("res://ui/menus/hangar_menu/hangar_menu.tscn")
static var production_menu_scene: PackedScene = load("res://ui/menus/production_menu/production_menu.tscn")
static var research_menu_scene: PackedScene = load("res://ui/menus/research_menu/research_menu.tscn")
