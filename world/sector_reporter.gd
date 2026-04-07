extends Node
class_name SectorReporter

# Holds and exposes the current mission message. SectorController calls the
# named methods below to set the message, then emits sector_changed itself.

var activity_tracker: ActivityTracker = null
var mission_message: String = "Deploying frontier station..."

func get_activity_display() -> int:
	return activity_tracker.get_activity_display() if activity_tracker else 0

func deploying() -> void:
	mission_message = "Station warping into sector..."

func station_launched() -> void:
	mission_message = "Sector live. The station has warped clear. Mine fast, make noise, and call it back when you want out."

func wave_incoming() -> void:
	mission_message = "Sector activity rising. Hostiles inbound."

func enemy_down() -> void:
	mission_message = "Hostile down. Sector heat is still climbing."

func asteroid_mined() -> void:
	mission_message = "Ore cracked loose. That definitely made some noise."

func run_complete() -> void:
	mission_message = "Sector pressure broken. Call the station and dock out."

func station_inbound() -> void:
	mission_message = "Calling station in. Hold the sector while it warps to your position."

func station_on_site() -> void:
	mission_message = "Station on-site. Move close and press F to dock."

func docking() -> void:
	mission_message = "Docking complete. Station spooling for departure."

func dock_complete() -> void:
	mission_message = "Docking complete. Sector map ready."

func redeploy_complete() -> void:
	mission_message = "Fresh sector deployment complete. Get back out there."

func move_closer_to_dock() -> void:
	mission_message = "Move closer to the station to dock."

func station_fallen() -> void:
	mission_message = "The station has fallen. Press Esc to return to the menu."

func bay_opened(seconds: int) -> void:
	mission_message = "Bay open. Station pulling you in — %ds. Move in range and press F to dock." % seconds

func bay_extended(seconds: int) -> void:
	mission_message = "Bay timer reset. %ds remaining. Press F when in range to dock." % seconds

func bay_timed_out() -> void:
	mission_message = "Bay closed. Press R to reopen."
