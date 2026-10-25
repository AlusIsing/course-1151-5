extends Archer
## 毒蛇射手（劇毒）：每次攻擊後幫目標疊一層毒（1 傷 × 3 回合，花 3 能量）。
## 挑目標：中毒層數最少的敵人，一樣少就打血少的。
## 花費 = 10 + 2 × 2 = 14 點


func _init() -> void:
	unit_name = "毒蛇射手"
	max_hp = 10
	attack = 2
	color = Color("#8bc34a")
	grid_position = Vector2i(0, 2)   # 後排左
	school = School.VENOM


func choose_target(enemies: Array[Unit]) -> Unit:
	var best: Unit = enemies[0]
	for enemy: Unit in enemies:
		if enemy.get_poison_stacks() < best.get_poison_stacks() \
				or (enemy.get_poison_stacks() == best.get_poison_stacks() and enemy.hp < best.hp):
			best = enemy
	return best


func on_attack(target: Unit) -> void:
	poison(target, 1, 3)
