extends Menu
class_name PauseMenu

@onready var resume_button: Button = %ResumeButton
@onready var return_button: Button = %ReturnToMenuButton

func _ready() -> void:
	super._ready()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		_on_resume_button_pressed()

func _on_resume_button_pressed() -> void:
	var main: Main = get_tree().current_scene as Main
	if main != null:
		main.resume_from_pause()

func _on_return_to_menu_button_pressed() -> void:
	var main: Main = get_tree().current_scene as Main
	if main != null:
		main.return_to_main_menu()
