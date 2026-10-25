extends Archer
## 毒蛇射手（劇毒）：每次攻擊後幫目標疊一層毒（1 傷 × 3 回合，花 3 能量）。
## 挑目標：中毒層數最少的敵人，一樣少就隨機挑（用 random_pick，結果由種子決定）。
## 花費 = 10 + 2 × 2 = 14 點


func _init() -> void:
	unit_name = "毒蛇射手"
	max_hp = 10
	attack = 2
	color = Color("#8bc34a")
	grid_position = Vector2i(0, 2)   # 後排左
	school = School.VENOM


func choose_target(enemies: Array[Unit]) -> Unit:
	var fewest: int = 999
	for enemy: Unit in enemies:
		fewest = mini(fewest, enemy.get_poison_stacks())
	var candidates: Array[Unit] = []
	for enemy: Unit in enemies:
		if enemy.get_poison_stacks() == fewest:
			candidates.append(enemy)
	return random_pick(candidates)


func on_attack(target: Unit) -> void:
	# 毒持續 3 回合；能量有 6 點就下 2 點的毒，把能量用完
	if get_energy() >= 6:
		poison(target, 2, 3)
	elif get_energy() >= 3:
		poison(target, 1, 3)
