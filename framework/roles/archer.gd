class_name Archer
extends Unit
## 射手（遠程）：可以攻擊敵方任何一格。
## 預設打血量最少的敵人（一樣少就打行動順序前面的）。
## 想換規則就覆寫 choose_target()，回傳 enemies 裡的其中一隻。
## choose_target() 只負責挑目標，裡面不能呼叫戰鬥 API。


func get_role() -> String:
	return "射手"


func choose_target(enemies: Array[Unit]) -> Unit:
	var best: Unit = null
	for enemy: Unit in enemies:
		if best == null or enemy.hp < best.hp:
			best = enemy
	return best
