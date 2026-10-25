extends Archer
## 骨弓手（死靈）：平常只普攻、把能量存起來，死的時候加上靈魂能量一次放大招：
## 對一隻血少的敵人先下詛咒再打一發，剩下的能量再補一刀。
## 挑目標：血最少的兩隻敵人裡隨機挑一隻（用 random_pick，結果由種子決定）。
## 花費 = 7 + 2 × 4 = 15 點


func _init() -> void:
	unit_name = "骨弓手"
	max_hp = 7
	attack = 4
	color = Color("#bdbdbd")
	grid_position = Vector2i(0, 2)   # 後排左
	school = School.NECRO


func choose_target(enemies: Array[Unit]) -> Unit:
	return _one_of_weakest(enemies)


func on_death() -> void:
	var target: Unit = _one_of_weakest(get_enemies())
	if target == null:
		return
	curse(target, 3)                          # 3 能量：下一次傷害 +3
	deal_damage(target, 5)                    # 5 能量：5 + 3 = 8 傷害
	target = _one_of_weakest(get_enemies())
	if target != null and get_energy() > 0:
		deal_damage(target, mini(5, get_energy()))


## 血最少的兩隻裡隨機挑一隻
func _one_of_weakest(enemies: Array[Unit]) -> Unit:
	if enemies.is_empty():
		return null
	var sorted: Array[Unit] = enemies.duplicate()
	sorted.sort_custom(func(a: Unit, b: Unit) -> bool: return a.hp < b.hp)
	return random_pick(sorted.slice(0, 2))
