extends Control
class_name MinimapDisplay

@export var radar_range: float = 55.0

const COLOR_PLAYER: Color    = Color(0.9,  0.95, 1.0,  1.0)
const COLOR_ENEMY: Color     = Color(0.95, 0.22, 0.18, 1.0)
const COLOR_ASTEROID: Color  = Color(0.55, 0.60, 0.70, 0.85)
const COLOR_STATION: Color   = Color(0.28, 0.95, 0.45, 1.0)
const COLOR_BORDER: Color    = Color(0.3,  0.5,  0.7,  0.3)
const COLOR_GRID: Color      = Color(0.2,  0.3,  0.45, 0.18)

var world: WorldRoot = null

func _process(_delta: float) -> void:
	if world != null:
		queue_redraw()

func _draw() -> void:
	if world == null:
		return

	var half: Vector2 = size * 0.5
	var radius: float = half.x - 1.0
	var scale_factor: float = radius / radar_range

	var player: PlayerShip = world.sector_controller.player
	var origin: Vector3 = player.global_position if (player != null and is_instance_valid(player)) else Vector3.ZERO

	# Background fill
	draw_circle(half, radius, Color(0.04, 0.06, 0.12, 0.88))

	# Grid rings
	for ring_frac in [0.4, 0.75]:
		draw_arc(half, radius * ring_frac, 0.0, TAU, 48, COLOR_GRID, 1.0)

	# Station — always clamped to edge if out of range
	if world.station_manager.station_present:
		var st_world: Vector3 = world.station_manager.station_anchor.global_position
		var st_rel: Vector2 = Vector2(st_world.x - origin.x, st_world.z - origin.z)
		var st_map: Vector2 = half + st_rel * scale_factor
		var to_st: Vector2 = st_map - half
		if to_st.length() > radius - 3.0:
			st_map = half + to_st.normalized() * (radius - 3.0)
		_draw_diamond(st_map, 5.0, COLOR_STATION)

	# Actors
	if world.actor_layer != null:
		for actor in world.actor_layer.get_children():
			if not is_instance_valid(actor):
				continue
			var a_rel: Vector2 = Vector2(
				actor.global_position.x - origin.x,
				actor.global_position.z - origin.z
			)
			var a_map: Vector2 = half + a_rel * scale_factor
			if (a_map - half).length() > radius - 1.0:
				continue

			if actor is PlayerShip:
				_draw_ship_chevron(a_map, actor as Node3D, COLOR_PLAYER)
			elif actor is EnemyShip:
				draw_circle(a_map, 3.5, COLOR_ENEMY)
			elif actor is AsteroidNode:
				var dot_r: float
				match (actor as AsteroidNode).size:
					AsteroidNode.AsteroidSize.LARGE:  dot_r = 4.5
					AsteroidNode.AsteroidSize.MEDIUM: dot_r = 2.8
					_:                                dot_r = 1.6
				draw_circle(a_map, dot_r, COLOR_ASTEROID)

	# Border ring
	draw_arc(half, radius, 0.0, TAU, 64, COLOR_BORDER, 1.2)

# Small forward-pointing chevron for the player
func _draw_ship_chevron(pos: Vector2, node: Node3D, color: Color) -> void:
	var fwd_world: Vector3 = -node.global_basis.z
	var fwd: Vector2 = Vector2(fwd_world.x, fwd_world.z).normalized()
	var right: Vector2 = Vector2(fwd.y, -fwd.x)
	var tip: Vector2    = pos + fwd * 5.5
	var bl: Vector2     = pos - fwd * 3.0 + right * 3.5
	var br: Vector2     = pos - fwd * 3.0 - right * 3.5
	draw_polygon([tip, bl, br], [color, color, color])

# Small rotated square for the station
func _draw_diamond(pos: Vector2, r: float, color: Color) -> void:
	draw_polygon(
		[pos + Vector2(0, -r), pos + Vector2(r, 0), pos + Vector2(0, r), pos + Vector2(-r, 0)],
		[color, color, color, color]
	)
