extends Warrior

func _init() -> void:
	unit_name = "小白"
	max_hp = 12
	attack = 4
	grid_position = Vector2i(2, 0)   # 前排右

func on_attack(target: Unit) -> void:
	if target != null and target.is_alive():
		deal_damage(target, 3)
