extends Archer
## 小冰（死靈射手）：冰晶琉璃的冰晶。挑血最少的兩隻敵人之一射擊，
## 攻擊後「冰晶彈射」：對另一隻敵人打 3 點（技能傷害會觸發對方 on_hurt，形成連鎖）。
## 花費 = 6 + 2 × 8 = 22 點

const PARTNER := "小yuri"


func _init() -> void:
	unit_name = "小冰"
	max_hp = 6
	attack = 8
	color = Color("#81d4fa")
	grid_position = Vector2i(1, 2)   # 後排中
	school = School.NECRO


func choose_target(enemies: Array[Unit]) -> Unit:
	var sorted: Array[Unit] = enemies.duplicate()
	sorted.sort_custom(func(a: Unit, b: Unit) -> bool: return a.hp < b.hp)
	return random_pick(sorted.slice(0, 2))


func on_attack(target: Unit) -> void:
	if get_energy() < 3:
		return
	var bounce: Unit = null
	for e: Unit in get_enemies():
		if e != target and (bounce == null or e.hp < bounce.hp):
			bounce = e
	if bounce == null and target.is_alive():
		bounce = target
	if bounce != null:
		deal_damage(bounce, 3)                 # 冰晶彈射


func on_hurt(_amount: int, _source: Unit) -> void:
	if is_alive() and hp <= 3 and get_energy() > 0:
		heal(self, mini(3, get_energy()))


func on_ally_death(ally: Unit) -> void:
	if ally.unit_name == PARTNER:
		buff_attack(self, 2)


func on_death() -> void:
	var target := _weakest_enemy()
	if target != null:
		deal_damage(target, 5)
	summon_token(4, 3)


func _weakest_enemy() -> Unit:
	var best: Unit = null
	for e: Unit in get_enemies():
		if best == null or e.hp < best.hp:
			best = e
	return best
