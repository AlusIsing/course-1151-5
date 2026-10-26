extends Warrior

const PARTNER := "小黑"
const ATK_LINES := ["喝啊啊啊！", "白光一閃！", "哥，看我的！", "這招你躲得掉嗎～？"]

func _init() -> void:
	unit_name = "小白"
	max_hp = 12
	attack = 4
	grid_position = Vector2i(2, 0)   # 前排右

func on_battle_start() -> void:
	say("嘿嘿，黑白雙煞來囉！準備被打爆吧！")

func on_attack(target: Unit) -> void:
	if target != null and target.is_alive():
		say(random_pick(ATK_LINES))
		deal_damage(target, 3)

func on_ally_death(ally: Unit) -> void:
	if ally.unit_name == PARTNER:
		say("哥——！！我絕對不會原諒你們！【白煞・覺醒】")
		buff_attack(self, 2)

func on_death() -> void:
	say("哥……對不起，我先走一步……")
