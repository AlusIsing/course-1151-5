extends Tank
## 堡壘（聖盾坦克）：每次攻擊後，給護盾最少的相鄰隊友 3 點護盾（花 3 能量）。
## 花費 = 24 + 2 × 2 = 28 點


func _init() -> void:
	unit_name = "堡壘"
	max_hp = 24
	attack = 2
	color = Color("#90caf9")
	grid_position = Vector2i(0, 0)   # 前排左
	school = School.AEGIS


func on_attack(_target: Unit) -> void:
	var best: Unit = self
	for ally: Unit in get_adjacent_allies():
		if ally.shield_points < best.shield_points:
			best = ally
	shield(best, 3)
