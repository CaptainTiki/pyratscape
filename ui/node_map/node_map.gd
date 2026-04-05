extends Control
class_name NodeMap

signal node_selected(node_id: int)

var map_data: NodeMapData = null
var hovered_node_id: int = -1

const NODE_RADIUS: float = 12.0
const FLEET_DOT_RADIUS: float = 4.0
const ASTEROID_DOT_RADIUS: float = 2.5
const HIT_RADIUS: float = 18.0
const PADDING: float = 30.0

const COLOR_CONNECTION: Color = Color(0.2, 0.3, 0.45, 0.5)
const COLOR_CONNECTION_CLEARED: Color = Color(0.3, 0.6, 0.4, 0.6)
const COLOR_NODE_DEFAULT: Color = Color(0.3, 0.4, 0.55, 1.0)
const COLOR_NODE_CLEARED: Color = Color(0.2, 0.7, 0.35, 1.0)
const COLOR_NODE_CURRENT: Color = Color(0.3, 0.85, 1.0, 1.0)
const COLOR_NODE_SELECTED: Color = Color(1.0, 1.0, 0.6, 1.0)
const COLOR_NODE_REACHABLE: Color = Color(0.5, 0.65, 0.8, 1.0)
const COLOR_HOVER_RING: Color = Color(1.0, 1.0, 1.0, 0.5)
const COLOR_POI: Color = Color(1.0, 0.85, 0.3, 1.0)
const COLOR_ASTEROID: Color = Color(0.55, 0.5, 0.45, 0.7)

var fleet_colors: Array[Color] = [
	Color(0.9, 0.85, 0.3, 0.9),   # yellow - low danger
	Color(1.0, 0.65, 0.2, 0.9),   # orange - medium
	Color(1.0, 0.3, 0.2, 0.9),    # red - high
]

func set_map_data(data: NodeMapData) -> void:
	map_data = data
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if map_data == null:
		return
	if event is InputEventMouseMotion:
		var old_hover: int = hovered_node_id
		hovered_node_id = _get_node_at_position(event.position)
		if hovered_node_id != old_hover:
			queue_redraw()
	elif event is InputEventMouseButton:
		var click_event: InputEventMouseButton = event as InputEventMouseButton
		if click_event.pressed and click_event.button_index == MOUSE_BUTTON_LEFT:
			var clicked_id: int = _get_node_at_position(click_event.position)
			if clicked_id >= 0 and map_data.is_adjacent_to_current(clicked_id):
				map_data.selected_node_id = clicked_id
				node_selected.emit(clicked_id)
				queue_redraw()

func _draw() -> void:
	if map_data == null:
		return

	# Background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.06, 1.0))

	# Connections
	for edge in map_data.connections:
		var from_node: NodeMapData.MapNode = map_data.get_node_by_id(edge.x)
		var to_node: NodeMapData.MapNode = map_data.get_node_by_id(edge.y)
		if from_node == null or to_node == null:
			continue
		var from_pos: Vector2 = _map_to_screen(from_node.map_position)
		var to_pos: Vector2 = _map_to_screen(to_node.map_position)
		var line_color: Color = COLOR_CONNECTION
		if from_node.is_cleared and to_node.is_cleared:
			line_color = COLOR_CONNECTION_CLEARED
		draw_line(from_pos, to_pos, line_color, 1.5)

	# Nodes
	for node in map_data.nodes:
		_draw_node(node)

func _draw_node(node: NodeMapData.MapNode) -> void:
	var pos: Vector2 = _map_to_screen(node.map_position)
	var is_reachable: bool = map_data.is_adjacent_to_current(node.id)

	# Base circle color
	var fill_color: Color = COLOR_NODE_DEFAULT
	if node.is_current:
		fill_color = COLOR_NODE_CURRENT
	elif node.is_cleared:
		fill_color = COLOR_NODE_CLEARED
	elif node.id == map_data.selected_node_id:
		fill_color = COLOR_NODE_SELECTED
	elif is_reachable:
		fill_color = COLOR_NODE_REACHABLE

	# Draw filled circle
	draw_circle(pos, NODE_RADIUS, fill_color)

	# Outline for current node
	if node.is_current:
		draw_arc(pos, NODE_RADIUS + 3.0, 0.0, TAU, 32, COLOR_NODE_CURRENT, 2.0)

	# Selected ring
	if node.id == map_data.selected_node_id:
		draw_arc(pos, NODE_RADIUS + 5.0, 0.0, TAU, 32, COLOR_NODE_SELECTED, 2.0)

	# Hover ring
	if node.id == hovered_node_id and is_reachable:
		draw_arc(pos, NODE_RADIUS + 4.0, 0.0, TAU, 32, COLOR_HOVER_RING, 1.5)

	# Enemy fleet dots - arrayed around the node
	if node.enemy_fleet_size > 0 and not node.is_current:
		var fleet_color: Color = _get_fleet_color(node.enemy_fleet_size)
		var dot_count: int = mini(node.enemy_fleet_size, 6)
		var dot_size: float = FLEET_DOT_RADIUS + float(node.enemy_fleet_size) * 0.5
		for i in range(dot_count):
			var angle: float = (float(i) / float(dot_count)) * TAU - PI * 0.5
			var offset: Vector2 = Vector2(cos(angle), sin(angle)) * (NODE_RADIUS + 8.0)
			draw_circle(pos + offset, dot_size, fleet_color)

	# Asteroid indicators - small grey clusters
	if node.asteroid_count > 0:
		var cluster_count: int = mini(node.asteroid_count / 2, 4)
		for i in range(cluster_count):
			var angle: float = PI * 0.8 + float(i) * 0.4
			var offset: Vector2 = Vector2(cos(angle), sin(angle)) * (NODE_RADIUS + 6.0)
			draw_circle(pos + offset, ASTEROID_DOT_RADIUS, COLOR_ASTEROID)

	# POI marker
	if node.has_poi:
		var diamond_pos: Vector2 = pos + Vector2(0.0, -(NODE_RADIUS + 10.0))
		var diamond_size: float = 4.0
		var points: PackedVector2Array = PackedVector2Array([
			diamond_pos + Vector2(0, -diamond_size),
			diamond_pos + Vector2(diamond_size, 0),
			diamond_pos + Vector2(0, diamond_size),
			diamond_pos + Vector2(-diamond_size, 0),
		])
		draw_colored_polygon(points, COLOR_POI)

func _get_fleet_color(fleet_size: int) -> Color:
	if fleet_size <= 2:
		return fleet_colors[0]
	elif fleet_size <= 4:
		return fleet_colors[1]
	else:
		return fleet_colors[2]

func _map_to_screen(map_pos: Vector2) -> Vector2:
	var draw_area: Vector2 = size - Vector2(PADDING * 2.0, PADDING * 2.0)
	return Vector2(
		PADDING + map_pos.x * draw_area.x,
		PADDING + map_pos.y * draw_area.y
	)

func _get_node_at_position(pos: Vector2) -> int:
	if map_data == null:
		return -1
	var closest_id: int = -1
	var closest_dist: float = HIT_RADIUS
	for node in map_data.nodes:
		var screen_pos: Vector2 = _map_to_screen(node.map_position)
		var dist: float = pos.distance_to(screen_pos)
		if dist < closest_dist:
			closest_dist = dist
			closest_id = node.id
	return closest_id
