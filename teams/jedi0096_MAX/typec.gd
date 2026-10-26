extends Mage
## typec（死靈法師）：什麼事都要「展開說說」，和 XiaoNas 是搭檔。攻擊後對目標下 4 層詛咒，讓下一擊更痛。
## XiaoNas 倒下時覺醒加攻；自己倒下時靈魂爆發並召喚分身。
## 花費 = 8 + 2 × 4 = 16 點

const PARTNER := "XiaoNas"
const ATK_LINES := ["展開說說？", "這招，我們展開說說。", "你這防禦……展開說說。", "說完了，倒下吧。"]


func _init() -> void:
	unit_name = "typec"
	max_hp = 8
	attack = 4
	color = Color("#212121")
	grid_position = Vector2i(0, 0)   # 前排左（red 掩護）
	school = School.NECRO


func on_battle_start() -> void:
	say("各位，今天這場我們展開說說。")


func on_attack(target: Unit) -> void:
	if target.is_alive() and get_energy() >= 4:
		say(random_pick(ATK_LINES))
		curse(target, 4)                       # 展開詛咒：目標下一次受傷 +4


func on_hurt(_amount: int, _source: Unit) -> void:
	if is_alive() and hp <= 4 and get_energy() > 0 and get_poison_stacks() == 0:
		heal(self, mini(3, get_energy()))


func on_ally_death(ally: Unit) -> void:
	if ally.unit_name == PARTNER:
		say("XiaoNas……！這件事，我要跟你們好好展開說說！【展開・覺醒】")
		buff_attack(self, 2)


func on_death() -> void:
	say("這個……下次再展開說說……")
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
