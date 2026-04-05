extends Node
class_name ActivityTracker

signal activity_changed
signal run_completed

var activity: float = 0.0
var time_in_node: float = 0.0
var danger_level: float = 0.3
var tracking_active: bool = false
var run_complete: bool = false

func _process(delta: float) -> void:
	if not tracking_active:
		return
	time_in_node += delta
	var rate_multiplier: float = 0.5 + (danger_level * 1.5)
	activity += (0.55 + (time_in_node * 0.055)) * rate_multiplier * delta
	activity_changed.emit()

func start_tracking() -> void:
	tracking_active = true

func stop_tracking() -> void:
	tracking_active = false

func reset(new_danger_level: float) -> void:
	activity = 0.0
	time_in_node = 0.0
	danger_level = new_danger_level
	run_complete = false
	tracking_active = false

func add_activity(amount: float) -> void:
	activity += amount
	activity_changed.emit()

func check_win_condition(enemies_remaining: int) -> void:
	if run_complete:
		return
	if enemies_remaining <= 0 and activity >= 35.0:
		run_complete = true
		run_completed.emit()

func get_activity_display() -> int:
	return int(round(activity))
