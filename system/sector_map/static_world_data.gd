extends Resource
class_name StaticWorldData

# A fully authored, deterministic world definition.
# Used as an alternative to SectorMapData.generate() so we can tune
# the simulation against a fixed map with labeled nodes.
#
# Author one of these either:
#   - in code via a builder script (see system/sector_map/static_worlds/)
#   - in the Godot inspector as a .tres resource

@export var world_name: String = "Untitled World"
@export var sectors: Array[StaticSectorData] = []
@export var connections: Array[Vector2i] = []

func get_sector_by_id(id: int) -> StaticSectorData:
	for s in sectors:
		if s.id == id:
			return s
	return null

func get_player_start_id() -> int:
	for s in sectors:
		if s.is_player_start:
			return s.id
	return 0

func get_enemy_home_id() -> int:
	for s in sectors:
		if s.is_enemy_home:
			return s.id
	return -1

func get_factory_ids() -> Array[int]:
	var ids: Array[int] = []
	for s in sectors:
		if s.is_factory:
			ids.append(s.id)
	return ids

func validate() -> Array[String]:
	# Returns a list of human-readable problems. Empty = valid.
	var errors: Array[String] = []

	if sectors.is_empty():
		errors.append("world has no sectors")
		return errors

	var seen_ids := {}
	var player_start_count := 0
	var enemy_home_count := 0
	for s in sectors:
		if s == null:
			errors.append("sectors array contains a null entry")
			continue
		if seen_ids.has(s.id):
			errors.append("duplicate sector id: %d" % s.id)
		seen_ids[s.id] = true
		if s.is_player_start:
			player_start_count += 1
		if s.is_enemy_home:
			enemy_home_count += 1

	if player_start_count != 1:
		errors.append("expected exactly 1 player start sector, found %d" % player_start_count)
	if enemy_home_count > 1:
		errors.append("expected at most 1 enemy home sector, found %d" % enemy_home_count)

	for c in connections:
		if not seen_ids.has(c.x) or not seen_ids.has(c.y):
			errors.append("connection references unknown sector: %s" % str(c))
		if c.x == c.y:
			errors.append("self-connection on sector %d" % c.x)

	return errors
