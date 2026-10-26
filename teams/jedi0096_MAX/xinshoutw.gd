extends Healer
## xinshoutw（聖盾補師）：愛喝酒、擅長跳躍攻擊。站正中央，每回合免費幫相鄰受傷的隊友回 attack 點血（請大家喝一杯）。
## 開場補血量 +1；Alus 倒下時再 +2；倒下時用剩下的能量跳躍攻擊血最少的敵人，再召喚分身。
## 花費 = 6 + 2 × 10 = 26 點

const PARTNER := "Alus"


func _init() -> void:
	unit_name = "xinshoutw"
	max_hp = 6
	attack = 10
	color = Color("#f8bbd0")
	grid_position = Vector2i(1, 1)   # 中排中（上下左右都補得到）
	school = School.AEGIS


func on_battle_start() -> void:
	say("先乾一杯再上！")
	buff_attack(self, 1)                       # 補血量 10 → 11


func on_hurt(_amount: int, _source: Unit) -> void:
	if is_alive() and hp <= 4 and get_energy() > 0 and get_poison_stacks() == 0:
		heal(self, mini(3, get_energy()))


func on_ally_death(ally: Unit) -> void:
	if ally.unit_name == PARTNER:
		buff_attack(self, 2)


func on_death() -> void:
	var target := _weakest_enemy()
	if target != null:
		say("喝完這杯——跳躍攻擊！")
		deal_damage(target, 5)
	summon_token(4, 3)


func _weakest_enemy() -> Unit:
	var best: Unit = null
	for e: Unit in get_enemies():
		if best == null or e.hp < best.hp:
			best = e
	return best
