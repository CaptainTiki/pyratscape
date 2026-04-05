extends Menu
class_name MainMenu

func _on_play_button_pressed() -> void:
	var game_data: GameData = GameData.instance
	if game_data == null:
		game_data = GameData.new()
		game_data.name = "GameData"
		get_tree().root.add_child(game_data)
	game_data.reset_for_new_game()
	manager.set_menu_data()
	var main: Main = get_tree().current_scene as Main
	if main != null:
		main.start_game()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
