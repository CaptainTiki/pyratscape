class_name PickupSpawner

const PICKUP_SCENE: PackedScene = preload("res://world/props/resource_pickup.tscn")

static func spawn(world: WorldRoot, origin: Vector3, scrap: int, crystals: int) -> void:
	if scrap > 0:
		var scrap_pickup: ResourcePickup = PICKUP_SCENE.instantiate() as ResourcePickup
		scrap_pickup.global_position = origin + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
		scrap_pickup.pickup_type = ResourcePickup.PickupType.SCRAP
		scrap_pickup.amount = scrap
		if world != null:
			world.sector_controller.register_pickup(scrap_pickup)
	if crystals > 0:
		var crystal_pickup: ResourcePickup = PICKUP_SCENE.instantiate() as ResourcePickup
		crystal_pickup.global_position = origin + Vector3(randf_range(-0.8, 0.8), 0.0, randf_range(-0.8, 0.8))
		crystal_pickup.pickup_type = ResourcePickup.PickupType.CRYSTAL
		crystal_pickup.amount = crystals
		if world != null:
			world.sector_controller.register_pickup(crystal_pickup)
