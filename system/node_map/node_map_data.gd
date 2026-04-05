extends RefCounted
class_name NodeMapData

class MapNode extends RefCounted:
	var id: int = 0
	var map_position: Vector2 = Vector2.ZERO
	var enemy_fleet_size: int = 0
	var asteroid_count: int = 5
	var danger_level: float = 0.0
	var has_poi: bool = false
	var is_cleared: bool = false
	var is_current: bool = false

var nodes: Array[MapNode] = []
var connections: Array[Vector2i] = []
var current_node_id: int = 0
var selected_node_id: int = -1

func generate(node_count: int = 14) -> void:
	nodes.clear()
	connections.clear()
	selected_node_id = -1
	current_node_id = 0

	_place_nodes(node_count)
	_build_connections()
	_assign_node_properties()

	nodes[0].is_current = true
	nodes[0].enemy_fleet_size = 1
	nodes[0].danger_level = 0.1
	nodes[0].asteroid_count = 7

func get_node_by_id(id: int) -> MapNode:
	if id >= 0 and id < nodes.size():
		return nodes[id]
	return null

func get_current_node() -> MapNode:
	return get_node_by_id(current_node_id)

func get_selected_node() -> MapNode:
	return get_node_by_id(selected_node_id)

func set_current_node(id: int) -> void:
	for node in nodes:
		node.is_current = false
	current_node_id = id
	var node: MapNode = get_node_by_id(id)
	if node != null:
		node.is_current = true

func is_adjacent_to_current(id: int) -> bool:
	for edge in connections:
		if (edge.x == current_node_id and edge.y == id) or (edge.y == current_node_id and edge.x == id):
			return true
	return false

func shuffle_enemy_fleets() -> void:
	for node in nodes:
		if node.is_current or node.is_cleared:
			continue
		node.enemy_fleet_size = clampi(node.enemy_fleet_size + randi_range(-1, 1), 0, 6)
		node.danger_level = clampf(float(node.enemy_fleet_size) / 6.0 + randf_range(-0.05, 0.05), 0.0, 1.0)

func _place_nodes(count: int) -> void:
	var columns: int = 4
	var rows: int = 4
	var spacing: Vector2 = Vector2(1.0 / float(columns), 1.0 / float(rows))
	var jitter: float = 0.12

	var slots: Array[Vector2] = []
	for row in range(rows):
		for col in range(columns):
			var center: Vector2 = Vector2(
				(float(col) + 0.5) * spacing.x,
				(float(row) + 0.5) * spacing.y
			)
			center.x += randf_range(-jitter, jitter)
			center.y += randf_range(-jitter, jitter)
			center.x = clampf(center.x, 0.06, 0.94)
			center.y = clampf(center.y, 0.06, 0.94)
			slots.append(center)

	# Shuffle and pick `count` slots, but always keep slot 0 (top-left, starting node)
	var remaining: Array[Vector2] = []
	for i in range(1, slots.size()):
		remaining.append(slots[i])
	remaining.shuffle()

	var chosen: Array[Vector2] = [slots[0]]
	for i in range(mini(count - 1, remaining.size())):
		chosen.append(remaining[i])

	for i in range(chosen.size()):
		var node: MapNode = MapNode.new()
		node.id = i
		node.map_position = chosen[i]
		nodes.append(node)

func _build_connections() -> void:
	if nodes.size() < 2:
		return

	# Minimum spanning tree via Prim's algorithm
	var in_tree: Array[bool] = []
	in_tree.resize(nodes.size())
	in_tree.fill(false)
	in_tree[0] = true
	var tree_count: int = 1

	while tree_count < nodes.size():
		var best_from: int = -1
		var best_to: int = -1
		var best_dist: float = INF
		for i in range(nodes.size()):
			if not in_tree[i]:
				continue
			for j in range(nodes.size()):
				if in_tree[j]:
					continue
				var dist: float = nodes[i].map_position.distance_squared_to(nodes[j].map_position)
				if dist < best_dist:
					best_dist = dist
					best_from = i
					best_to = j
		if best_from < 0:
			break
		connections.append(Vector2i(best_from, best_to))
		in_tree[best_to] = true
		tree_count += 1

	# Add extra edges for loops (connect each node to nearest non-connected neighbor)
	var extra_count: int = nodes.size() / 3
	for _attempt in range(extra_count):
		var from_id: int = randi_range(0, nodes.size() - 1)
		var nearest_id: int = -1
		var nearest_dist: float = INF
		for j in range(nodes.size()):
			if j == from_id or _has_connection(from_id, j):
				continue
			var dist: float = nodes[from_id].map_position.distance_squared_to(nodes[j].map_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_id = j
		if nearest_id >= 0:
			connections.append(Vector2i(from_id, nearest_id))

func _has_connection(a: int, b: int) -> bool:
	for edge in connections:
		if (edge.x == a and edge.y == b) or (edge.y == a and edge.x == b):
			return true
	return false

func _assign_node_properties() -> void:
	for node in nodes:
		# Row-based difficulty: nodes further down the map are harder
		var row_factor: float = node.map_position.y
		node.enemy_fleet_size = clampi(int(row_factor * 5.0) + randi_range(0, 1), 0, 6)
		node.asteroid_count = clampi(randi_range(3, 8) + int((1.0 - row_factor) * 3.0), 3, 10)
		node.danger_level = clampf(float(node.enemy_fleet_size) / 6.0 + randf_range(-0.1, 0.1), 0.0, 1.0)
		node.has_poi = randf() < 0.15
