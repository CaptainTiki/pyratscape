extends Menu
class_name ResearchMenu

func _ready() -> void:
	super._ready()

func _on_return_button_pressed() -> void:
	if manager != null:
		manager.show_menu(Menu.Type.STATION)
