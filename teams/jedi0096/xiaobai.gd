extends Warrior
## 小白（死靈戰士）：黑白雙煞的弟弟。攻擊後對目標下 3 層詛咒，讓下一擊更痛。
## 小黑倒下時覺醒加攻；自己倒下時靈魂爆發並召喚分身。
## 花費 = 8 + 2 × 4 = 16 點

const PARTNER := "小黑"
const ATK_LINES := ["賀啊啊啊！", "白光一閃！", "哥，看我的！", "這招你躲得掉嗎～？"]


func _init() -> void:
	unit_name = "小白"
	max_hp = 8
	attack = 4
	color = Color("#fafafa")
	grid_position = Vector2i(2, 1)   # 中排右
	school = School.NECRO


func on_battle_start() -> void:
	say("嘻嘻，黑白雙煞來囉！準備被打爆吧！")


func on_attack(target: Unit) -> void:
	if target.is_alive() and get_energy() >= 3:
		say(random_pick(ATK_LINES))
		curse(target, 3)                       # 白煞詛咒：目標下一次受傷 +3


func on_hurt(_amount: int, _source: Unit) -> void:
	if is_alive() and hp <= 4 and get_energy() > 0 and get_poison_stacks() == 0:
		heal(self, mini(3, get_energy()))


func on_ally_death(ally: Unit) -> void:
	if ally.unit_name == PARTNER:
		say("哥——！！我絕對不會原諒你們！【白煞・覺醒】")
		buff_attack(self, 2)


func on_death() -> void:
	say("嘿嘿，以為這樣就贏了？")
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
