extends Warrior
## 狂戰士（狂血）：攻擊後吸血 1 點（花 2 能量），能量不夠就算了。
## 花費 = 20 + 2 × 4 = 28 點


func _init() -> void:
	unit_name = "狂戰士"
	max_hp = 20
	attack = 4
	color = Color("#e57373")
	grid_position = Vector2i(0, 0)   # 前排左
	school = School.BLOOD


func on_attack(target: Unit) -> void:
	# 能量全部拿來吸血（每 1 點傷害花 2 能量）
	if target.is_alive() and get_energy() >= 2:
		drain(target, get_energy() / 2)
