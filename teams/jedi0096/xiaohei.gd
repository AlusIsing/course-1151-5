extends Warrior
## 小黑（死靈戰士）：黑白雙煞的哥哥。攻擊後對目標下 3 層詛咒，讓下一擊更痛。
## 小白倒下時覺醒加攻；自己倒下時靈魂爆發並召喚分身。
## 花費 = 8 + 2 × 4 = 16 點

const PARTNER := "小白"
const ATK_LINES := ["……閉嘴，倒下。", "黑影斬。", "太慢了。", "你看不見我。"]


func _init() -> void:
	unit_name = "小黑"
	max_hp = 8
	attack = 4
	color = Color("#212121")
	grid_position = Vector2i(0, 1)   # 中排左
	school = School.NECRO


func on_battle_start() -> void:
	say("黑與白，不可分割——黑白雙煞，參上！")


func on_attack(target: Unit) -> void:
	if target.is_alive() and get_energy() >= 3:
		say(random_pick(ATK_LINES))
		curse(target, 3)                       # 黑煞詛咒：目標下一次受傷 +3


func on_hurt(_amount: int, _source: Unit) -> void:
	if is_alive() and hp <= 4 and get_energy() > 0 and get_poison_stacks() == 0:
		heal(self, mini(3, get_energy()))


func on_ally_death(ally: Unit) -> void:
	if ally.unit_name == PARTNER:
		say("小白……！你們，全部都要陪葬！【黑煞・覺醒】")
		buff_attack(self, 2)


func on_death() -> void:
	say("黑影……不滅。")
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
