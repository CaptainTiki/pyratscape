extends Node3D
class_name GameRoot

@onready var world: WorldRoot = $World
@onready var hud: Hud = $CanvasLayer/HUD
@onready var debug_overlay: DebugOverlay = $CanvasLayer/DebugOverlay
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect

func _ready() -> void:
	hud.bind_world(world)
	debug_overlay.bind_world(world)
	world.sector_controller.dock_sequence_finished.connect(_on_world_dock_sequence_finished)
	fade_rect.modulate.a = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			debug_overlay.visible = !debug_overlay.visible
			get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	var main: Main = get_tree().current_scene as Main
	if main == null:
		return
	get_tree().paused = true
	main.show_pause_menu()

func return_to_menu() -> void:
	var main: Main = get_tree().current_scene as Main
	if main != null:
		main.return_to_main_menu()

func fade_from_black() -> void:
	fade_rect.show()
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.35)

func _on_world_dock_sequence_finished() -> void:
	fade_rect.show()
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	tween.finished.connect(_show_station_menu)

func _show_station_menu() -> void:
	var main: Main = get_tree().current_scene as Main
	if main != null:
		main.show_station_menu()
	# Don't fade from black — menus have their own dark background.
	# FadeRect stays opaque so the game world is hidden behind menus.
