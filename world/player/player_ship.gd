extends ShipEntity
class_name PlayerShip

var world: WorldRoot = null

@onready var movement: ShipMovement = $ShipMovement
@onready var weapons: WeaponSystem = $WeaponSystem
@onready var tractor: TractorSystem = $TractorSystem
@onready var hull_component: HullComponent = $HullComponent

@onready var muzzle_left: Node3D = $MuzzleLeft
@onready var muzzle_right: Node3D = $MuzzleRight
@onready var missile_muzzle: Node3D = $MissileMuzzle
@onready var tractor_area: Area3D = $TractorArea
@onready var tractor_visual: Node3D = $TractorVisual
@onready var ship_visual: Node3D = $ShipVisual
@onready var pod_visual: Node3D = $PodVisual
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _in_pod_mode: bool = false

func _on_projectile_parent_set() -> void:
	if weapons != null:
		weapons.projectile_parent = projectile_parent

func _ready() -> void:
	health = hull_component
	hull_component.destroyed.connect(_on_hull_destroyed)
	movement.ship = self
	movement.collision_handler = $CollisionDamageHandler
	weapons.source = self
	weapons.projectile_parent = projectile_parent
	weapons.muzzle_left = muzzle_left
	weapons.muzzle_right = muzzle_right
	weapons.missile_muzzle = missile_muzzle
	tractor.ship = self
	tractor.tractor_area = tractor_area
	tractor.tractor_visual = tractor_visual
	tractor.initialize()
	_sync_from_game_data()

func _input(event: InputEvent) -> void:
	movement.handle_input_event(event)
	if event.is_action_pressed("call_station") and world != null:
		world.sector_controller.try_call_or_open_bay()

func _physics_process(delta: float) -> void:
	if not visible:
		return
	if world != null:
		movement.external_velocity = world.sector_controller.get_bay_pull_force(global_position)
	movement.tick(delta)
	if not _in_pod_mode:
		weapons.tick(delta)
		tractor.tick(delta)
	if Input.is_action_just_pressed("interact") and world != null:
		world.sector_controller.try_interact_at_station()

func switch_to_pod() -> void:
	_in_pod_mode = true

	# Swap visuals
	ship_visual.visible = false
	pod_visual.visible = true

	# Resize collision to pod size
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.2
	collision_shape.shape = shape

	# Reset health to pod values (40/40 so HUD shows fresh pod health)
	hull_component.max_health = 40
	hull_component.health = 40
	if GameData.instance != null:
		GameData.instance.player_max_hull = 40
		GameData.instance.player_hull = 40

	# Slightly slower movement for pod feel
	if GameData.instance != null:
		movement.base_move_speed = GameData.instance.player_move_speed * 0.85

	# Ensure tractor is inactive (resource_pickup checks this)
	tractor.tractor_active = false

func _on_hull_destroyed() -> void:
	hull_component.destroyed.disconnect(_on_hull_destroyed)
	switch_to_pod()
	# Reconnect so pod death also triggers this (pod death = game over message)
	hull_component.destroyed.connect(_on_pod_destroyed)

	if world != null:
		world.sector_controller.mission_message = "Ship destroyed — reach the station in your escape pod."
		world.world_state_changed.emit()

func _on_pod_destroyed() -> void:
	if world != null:
		world.sector_controller.mission_message = "Escape pod destroyed. Return with Esc and try again."
		world.world_state_changed.emit()
	queue_free()

func _sync_from_game_data() -> void:
	if GameData.instance == null:
		return
	movement.base_move_speed = GameData.instance.player_move_speed
	movement.boost_multiplier = GameData.instance.player_boost_multiplier
	hull_component.max_health = GameData.instance.player_max_hull
	hull_component.health = GameData.instance.player_hull
	weapons.fire_cooldown = GameData.instance.player_fire_rate
	weapons.projectile_damage = GameData.instance.player_damage
	weapons.missile_damage = GameData.instance.player_mining_damage
	tractor.set_range(GameData.instance.player_tractor_range)
