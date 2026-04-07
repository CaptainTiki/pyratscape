class_name ShipHullConfig
extends Resource

@export_group("Identity")
@export var display_name: String = "Ship"
@export var is_escape_pod: bool = false

@export_group("Dimensions")
@export var collision_radius: float = 0.8
@export var collision_height: float = 2.2

@export_group("Stats")
@export var max_health: int = 100
@export var speed_multiplier: float = 1.0

@export_group("Systems")
@export var has_weapons: bool = true
@export var has_tractor: bool = true

@export_group("Visual")
@export var ship_visual_visible: bool = true
@export var pod_visual_visible: bool = false
