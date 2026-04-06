extends Node
class_name CollisionDamageHandler

signal collision_hit(damage: int)

@export var damage_scale: float = 0.2
@export var cooldown: float = 0.3
@export var min_impact_speed: float = 0.0

var _timer: float = 0.0

func tick(body: CharacterBody3D, delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	if _timer > 0.0:
		return
	var highest_impact: float = 0.0
	var impacted_bodies: Array[Node] = []
	for i in range(body.get_slide_collision_count()):
		var collision: KinematicCollision3D = body.get_slide_collision(i)
		var collider: Node = collision.get_collider() as Node
		if collider == null or collider == body:
			continue
		var impact_speed: float = body.velocity.length()
		if impact_speed < min_impact_speed:
			continue
		highest_impact = maxf(highest_impact, impact_speed)
		if not impacted_bodies.has(collider):
			impacted_bodies.append(collider)
	if highest_impact <= 0.0:
		return
	var damage: int = maxi(1, int(round(highest_impact * damage_scale)))
	collision_hit.emit(damage)
	for collider in impacted_bodies:
		if collider.has_method("apply_collision_damage"):
			collider.apply_collision_damage(damage)
		elif collider.has_method("apply_damage"):
			collider.apply_damage(damage)
	_timer = cooldown
