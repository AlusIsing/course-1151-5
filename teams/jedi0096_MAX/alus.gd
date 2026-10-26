extends Archer
## Alus（聖盾射手）：野豬騎士，騎著野豬在後排放箭。挑血最少的兩隻敵人之一射擊。
## 攻擊後「獠牙彈射」：對另一隻敵人打 3 點（技能傷害會觸發對方 on_hurt，形成連鎖）。
## 倒下時「野豬衝撞」：對血最少的兩隻敵人各打 3 點，再召喚分身。
## 花費 = 10 + 2 × 6 = 22 點

const PARTNER := "xinshoutw"


func _init() -> void:
	unit_name = "Alus"
	max_hp = 10
	attack = 6
	color = Color("#81d4fa")
	grid_position = Vector2i(1, 2)   # 後排中
	school = School.AEGIS


func on_battle_start() -> void:
	say("野豬騎士 Alus，衝啊！")


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
		deal_damage(bounce, 3)                 # 獠牙彈射


func on_hurt(_amount: int, _source: Unit) -> void:
	if is_alive() and hp <= 4 and get_energy() > 0 and get_poison_stacks() == 0:
		heal(self, mini(3, get_energy()))


func on_ally_death(ally: Unit) -> void:
	if ally.unit_name == PARTNER:
		buff_attack(self, 2)


func on_death() -> void:
	var sorted: Array[Unit] = get_enemies()
	sorted.sort_custom(func(a: Unit, b: Unit) -> bool: return a.hp < b.hp)
	for e: Unit in sorted.slice(0, 2):
		deal_damage(e, 3)                      # 野豬衝撞：撞向最虛弱的兩隻敵人
	summon_token(4, 3)


func _weakest_enemy() -> Unit:
	var best: Unit = null
	for e: Unit in get_enemies():
		if best == null or e.hp < best.hp:
			best = e
	return best
