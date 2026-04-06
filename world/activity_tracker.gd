extends Node
class_name ActivityTracker

signal activity_changed
signal run_completed

@export var base_rate_multiplier: float = 0.5
@export var danger_rate_scale: float = 1.5
@export var base_activity_rate: float = 0.55
@export var activity_time_scale: float = 0.055
@export var win_activity_threshold: float = 35.0

var activity: float = 0.0
var time_in_node: float = 0.0
var danger_level: float = 0.3
var tracking_active: bool = false
var run_complete: bool = false

func _process(delta: float) -> void:
	if not tracking_active:
		return
	time_in_node += delta
	var rate_multiplier: float = base_rate_multiplier + (danger_level * danger_rate_scale)
	activity += (base_activity_rate + (time_in_node * activity_time_scale)) * rate_multiplier * delta
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
	if enemies_remaining <= 0 and activity >= win_activity_threshold:
		run_complete = true
		run_completed.emit()

func get_activity_display() -> int:
	return int(round(activity))
