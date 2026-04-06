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

func _on_projectile_parent_set() -> void:
	if weapons != null:
		weapons.projectile_parent = projectile_parent

func _ready() -> void:
	health = hull_component
	hull_component.destroyed.connect(_on_hull_destroyed)
	movement.ship = self
	movement.hull_component = hull_component
	weapons.source = self
	weapons.projectile_parent = projectile_parent
	weapons.muzzle_left = muzzle_left
	weapons.muzzle_right = muzzle_right
	weapons.missile_muzzle = missile_muzzle
	tractor.ship = self
	tractor.tractor_area = tractor_area
	tractor.tractor_visual = tractor_visual
	_sync_from_game_data()

func _input(event: InputEvent) -> void:
	movement.handle_input_event(event)

func _physics_process(delta: float) -> void:
	if not visible:
		return
	movement.tick(delta)
	weapons.tick(delta)
	tractor.tick(delta)
	if Input.is_action_just_pressed("interact") and world != null:
		world.try_interact_at_station()

func _on_hull_destroyed() -> void:
	if world != null:
		world.mission_message = "Your ship was destroyed. Return with Esc and try again."
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
