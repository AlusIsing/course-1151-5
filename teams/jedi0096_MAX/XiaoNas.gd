extends Mage
## XiaoNas（死靈法師）：四海為家的流浪法師，和 typec 是搭檔。攻擊後對目標下 4 層詛咒，讓下一擊更痛。
## typec 倒下時覺醒加攻；自己倒下時靈魂爆發並召喚分身。
## 花費 = 8 + 2 × 4 = 16 點

const PARTNER := "typec"
const ATK_LINES := ["四海為家，走到哪打到哪！", "這裡不錯，就在這落腳吧。", "typec，看好了！", "下一站，你的墓地～"]


func _init() -> void:
	unit_name = "XiaoNas"
	max_hp = 8
	attack = 4
	color = Color("#fafafa")
	grid_position = Vector2i(2, 0)   # 前排右（red 掩護）
	school = School.NECRO


func on_battle_start() -> void:
	say("四海為家，今天就在這裡紮營！")


func on_attack(target: Unit) -> void:
	if target.is_alive() and get_energy() >= 4:
		say(random_pick(ATK_LINES))
		curse(target, 4)                       # 流浪詛咒：目標下一次受傷 +4


func on_hurt(_amount: int, _source: Unit) -> void:
	if is_alive() and hp <= 4 and get_energy() > 0 and get_poison_stacks() == 0:
		heal(self, mini(3, get_energy()))


func on_ally_death(ally: Unit) -> void:
	if ally.unit_name == PARTNER:
		say("typec——！！我絕對不會原諒你們！【四海・覺醒】")
		buff_attack(self, 2)


func on_death() -> void:
	say("沒關係……我本來就四海為家。")
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
