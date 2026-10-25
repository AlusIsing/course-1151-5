extends Archer
## 骨弓手（死靈）：平常只普攻、把能量存起來（滿了才花一點）；
## 死的時候對血最少的敵人先下詛咒再打一發，剩下的能量再補一刀。
## 花費 = 7 + 2 × 4 = 15 點


func _init() -> void:
	unit_name = "骨弓手"
	max_hp = 7
	attack = 4
	color = Color("#bdbdbd")
	grid_position = Vector2i(0, 2)   # 後排左
	school = School.NECRO


func on_attack(target: Unit) -> void:
	# 能量最多存 6 點，滿了的話每回合回復的會浪費掉，所以先花掉 3 點
	if target.is_alive() and get_energy() >= 6:
		curse(target, 3)


func on_death() -> void:
	var target: Unit = _weakest()
	if target == null:
		return
	curse(target, 3)                          # 3 能量：下一次傷害 +3
	deal_damage(target, 5)                    # 5 能量：5 + 3 = 8 傷害
	target = _weakest()
	if target != null and get_energy() > 0:
		deal_damage(target, mini(5, get_energy()))


func _weakest() -> Unit:
	var best: Unit = null
	for enemy: Unit in get_enemies():
		if best == null or enemy.hp < best.hp:
			best = enemy
	return best
