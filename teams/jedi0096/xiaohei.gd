extends Warrior

const PARTNER := "小白"
const ATK_LINES := ["……閉嘴，倒下。", "黑影斬。", "太慢了。", "你看不見我。"]

func _init() -> void:
	unit_name = "小黑"
	max_hp = 12
	attack = 4
	grid_position = Vector2i(0, 0)   # 前排左

func on_battle_start() -> void:
	say("黑與白，不可分割——黑白雙煞，參上！")

func on_attack(target: Unit) -> void:
	if target != null and target.is_alive():
		say(random_pick(ATK_LINES))
		deal_damage(target, 3)

func on_ally_death(ally: Unit) -> void:
	if ally.unit_name == PARTNER:
		say("小白……！你們，全部都要陪葬！【黑煞・覺醒】")
		buff_attack(self, 2)

func on_death() -> void:
	say("小白……剩下的，交給你了……")
