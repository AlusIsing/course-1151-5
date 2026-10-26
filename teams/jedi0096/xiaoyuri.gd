extends Archer

const PARTNER := "小冰"

func _init() -> void:
	unit_name = "小yuri"
	max_hp = 6
	attack = 7
	grid_position = Vector2i(1, 2)   # 後排中

func on_attack(target: Unit) -> void:
	if target != null and target.is_alive():
		deal_damage(target, 3)

func on_ally_death(ally: Unit) -> void:
	if ally.unit_name == PARTNER:
		buff_attack(self, 2)
