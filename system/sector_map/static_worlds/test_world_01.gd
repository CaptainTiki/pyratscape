extends RefCounted
class_name TestWorld01

# Scaffolding world for simulation tuning. 6 nodes in a rough line from
# Home Station (player start) out to The Foundry (enemy home).
#
#   [Home Station] --- [Inner Belt] --- [Midway] --- [Crossroads] --- [Outer Yards] --- [The Foundry]
#                                           \                                       /
#                                            +------------- detour ----------------+
#
# Distance from Home Station to The Foundry: 5 jumps along the main line,
# or 4 jumps via the Crossroads -> Outer Yards detour.
#
# This world is intentionally small, hand-placed, and fully labeled so
# tests can say things like "after 10 minutes, enemies at Midway == 3".

static func build() -> StaticWorldData:
	var world := StaticWorldData.new()
	world.world_name = "Test World 01"

	world.sectors = [
		_make_sector(0, "Home Station", Vector2(0.10, 0.50),
			0, 0, 600, 7, false, true, false),
		_make_sector(1, "Inner Belt", Vector2(0.28, 0.50),
			0, 0, 1200, 6, false, false, false),
		_make_sector(2, "Midway", Vector2(0.46, 0.50),
			0, 0, 1500, 5, false, false, false),
		_make_sector(3, "Crossroads", Vector2(0.62, 0.42),
			1, 0, 1800, 5, false, false, false),
		_make_sector(4, "Outer Yards", Vector2(0.78, 0.58),
			2, 1, 2000, 4, true, false, false),
		_make_sector(5, "The Foundry", Vector2(0.92, 0.50),
			4, 2, 2400, 3, true, false, true),
	]

	world.connections = [
		Vector2i(0, 1),
		Vector2i(1, 2),
		Vector2i(2, 3),
		Vector2i(3, 4),
		Vector2i(4, 5),
		Vector2i(2, 4),  # detour: Midway directly to Outer Yards
	]

	return world

static func _make_sector(
	id: int,
	display_name: String,
	map_position: Vector2,
	starting_fighters: int,
	starting_miners: int,
	starting_resources: int,
	asteroid_count: int,
	is_factory: bool,
	is_player_start: bool,
	is_enemy_home: bool,
) -> StaticSectorData:
	var s := StaticSectorData.new()
	s.id = id
	s.display_name = display_name
	s.map_position = map_position
	s.starting_fighters = starting_fighters
	s.starting_miners = starting_miners
	s.starting_resources = starting_resources
	s.asteroid_count = asteroid_count
	s.is_factory = is_factory
	s.is_player_start = is_player_start
	s.is_enemy_home = is_enemy_home
	return s
