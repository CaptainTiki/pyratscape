extends RefCounted
class_name SectorMapData

class SectorData extends RefCounted:
	var id: int = 0
	var map_position: Vector2 = Vector2.ZERO
	var enemy_fleet_size: int = 0
	var asteroid_count: int = 5
	var danger_level: float = 0.0
	var has_poi: bool = false
	var is_cleared: bool = false
	var is_current: bool = false
	var available_resources: int = 0

var sectors: Array[SectorData] = []
var connections: Array[Vector2i] = []
var current_sector_id: int = 0
var selected_sector_id: int = -1

func generate(sector_count: int = 14) -> void:
	sectors.clear()
	connections.clear()
	selected_sector_id = -1
	current_sector_id = 0

	_place_sectors(sector_count)
	_build_connections()
	_assign_sector_properties()

	sectors[0].is_current = true
	sectors[0].enemy_fleet_size = 1
	sectors[0].danger_level = 0.1
	sectors[0].asteroid_count = 7

func load_from_static(static_world: StaticWorldData) -> void:
	# Populate this SectorMapData from a hand-authored StaticWorldData.
	# Use this instead of generate() when tuning against a fixed map.
	sectors.clear()
	connections.clear()
	selected_sector_id = -1
	current_sector_id = 0

	if static_world == null:
		push_warning("load_from_static called with null StaticWorldData")
		return

	var errors := static_world.validate()
	if not errors.is_empty():
		for e in errors:
			push_warning("StaticWorldData validation: %s" % e)

	for s in static_world.sectors:
		var sector := SectorData.new()
		sector.id = s.id
		sector.map_position = s.map_position
		sector.asteroid_count = s.asteroid_count
		sector.available_resources = s.starting_resources
		sector.enemy_fleet_size = s.starting_fighters
		sector.danger_level = clampf(float(s.starting_fighters) / 6.0, 0.0, 1.0)
		sector.has_poi = s.has_poi
		sectors.append(sector)

	for c in static_world.connections:
		connections.append(c)

	current_sector_id = static_world.get_player_start_id()
	var current := get_sector_by_id(current_sector_id)
	if current != null:
		current.is_current = true

func get_sector_by_id(id: int) -> SectorData:
	if id >= 0 and id < sectors.size():
		return sectors[id]
	return null

func get_current_sector() -> SectorData:
	return get_sector_by_id(current_sector_id)

func get_selected_sector() -> SectorData:
	return get_sector_by_id(selected_sector_id)

func set_current_sector(id: int) -> void:
	for sector in sectors:
		sector.is_current = false
	current_sector_id = id
	var sector: SectorData = get_sector_by_id(id)
	if sector != null:
		sector.is_current = true

func is_adjacent_to_current(id: int) -> bool:
	for edge in connections:
		if (edge.x == current_sector_id and edge.y == id) or (edge.y == current_sector_id and edge.x == id):
			return true
	return false

func shuffle_enemy_fleets() -> void:
	for sector in sectors:
		if sector.is_current or sector.is_cleared:
			continue
		sector.enemy_fleet_size = clampi(sector.enemy_fleet_size + randi_range(-1, 1), 0, 6)
		sector.danger_level = clampf(float(sector.enemy_fleet_size) / 6.0 + randf_range(-0.05, 0.05), 0.0, 1.0)

func _place_sectors(count: int) -> void:
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

	var remaining: Array[Vector2] = []
	for i in range(1, slots.size()):
		remaining.append(slots[i])
	remaining.shuffle()

	var chosen: Array[Vector2] = [slots[0]]
	for i in range(mini(count - 1, remaining.size())):
		chosen.append(remaining[i])

	for i in range(chosen.size()):
		var sector: SectorData = SectorData.new()
		sector.id = i
		sector.map_position = chosen[i]
		sectors.append(sector)

func _build_connections() -> void:
	if sectors.size() < 2:
		return

	var in_tree: Array[bool] = []
	in_tree.resize(sectors.size())
	in_tree.fill(false)
	in_tree[0] = true
	var tree_count: int = 1

	while tree_count < sectors.size():
		var best_from: int = -1
		var best_to: int = -1
		var best_dist: float = INF
		for i in range(sectors.size()):
			if not in_tree[i]:
				continue
			for j in range(sectors.size()):
				if in_tree[j]:
					continue
				var dist: float = sectors[i].map_position.distance_squared_to(sectors[j].map_position)
				if dist < best_dist:
					best_dist = dist
					best_from = i
					best_to = j
		if best_from < 0:
			break
		connections.append(Vector2i(best_from, best_to))
		in_tree[best_to] = true
		tree_count += 1

	var extra_count: int = sectors.size() / 3
	for _attempt in range(extra_count):
		var from_id: int = randi_range(0, sectors.size() - 1)
		var nearest_id: int = -1
		var nearest_dist: float = INF
		for j in range(sectors.size()):
			if j == from_id or _has_connection(from_id, j):
				continue
			var dist: float = sectors[from_id].map_position.distance_squared_to(sectors[j].map_position)
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

func _assign_sector_properties() -> void:
	for sector in sectors:
		var row_factor: float = sector.map_position.y
		sector.enemy_fleet_size = clampi(int(row_factor * 5.0) + randi_range(0, 1), 0, 6)
		sector.asteroid_count = clampi(randi_range(3, 8) + int((1.0 - row_factor) * 3.0), 3, 10)
		sector.danger_level = clampf(float(sector.enemy_fleet_size) / 6.0 + randf_range(-0.1, 0.1), 0.0, 1.0)
		sector.has_poi = randf() < 0.15
