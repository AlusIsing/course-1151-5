extends Archer
## 哨兵（射手，沒有流派）：躲在中間被補師包圍，每次攻擊後多射一箭（花 3 能量）。
## 挑目標：血最少的兩隻敵人裡隨機挑一隻。
## 花費 = 8 + 2 × 4 = 16 點


func _init() -> void:
	unit_name = "哨兵"
	max_hp = 8
	attack = 4
	color = Color("#ffcc80")
	grid_position = Vector2i(1, 1)   # 中排中


func choose_target(enemies: Array[Unit]) -> Unit:
	var sorted: Array[Unit] = enemies.duplicate()
	sorted.sort_custom(func(a: Unit, b: Unit) -> bool: return a.hp < b.hp)
	return random_pick(sorted.slice(0, 2))


func on_attack(target: Unit) -> void:
	if target.is_alive():
		deal_damage(target, 3)
