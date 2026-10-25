extends Archer
## 哨兵（射手，沒有流派）：躲在中間被補師包圍，每次攻擊後多射一箭（花 3 能量）。
## 花費 = 8 + 2 × 4 = 16 點


func _init() -> void:
	unit_name = "哨兵"
	max_hp = 8
	attack = 4
	color = Color("#ffcc80")
	grid_position = Vector2i(1, 1)   # 中排中


func on_attack(target: Unit) -> void:
	if target.is_alive():
		deal_damage(target, 3)
