extends Tank
## 腐毒護衛：在前排提供掩護減傷，普攻後施加毒素

func _init() -> void:
	unit_name = "腐毒護衛"
	max_hp = 30
	attack = 1
	color = Color("#1b5e20")
	grid_position = Vector2i(1, 0)
	school = School.VENOM

func on_attack(target: Unit) -> void:
	if target.is_alive() and get_energy() >= 3:
		poison(target, 1, 3)
