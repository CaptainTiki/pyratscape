extends HealthComponent
class_name HullComponent

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if GameData.instance != null:
		GameData.instance.player_hull = health
	if health <= 0:
		destroyed.emit()
