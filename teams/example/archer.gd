extends Archer
## 範例角色：弓手（射手）
## 覆寫 choose_target()：專打 max_hp 最高的敵人（通常就是 Boss）。
## 花費 = 10 + 2 × 4 = 18 點


func _init() -> void:
	unit_name = "弓手"
	max_hp = 10
	attack = 4
	color = Color("#ffcc80")


func choose_target(enemies: Array[Unit]) -> Unit:
	var best: Unit = enemies[0]
	for enemy: Unit in enemies:
		if enemy.max_hp > best.max_hp:
			best = enemy
	return best
