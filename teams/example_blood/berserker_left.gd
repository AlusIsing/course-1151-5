extends Warrior
## 狂戰士（狂血）：攻擊後吸血 1 點（花 2 能量），能量不夠就算了。
## 花費 = 18 + 2 × 4 = 26 點


func _init() -> void:
	unit_name = "狂戰士"
	max_hp = 18
	attack = 4
	color = Color("#e57373")
	grid_position = Vector2i(0, 0)   # 前排左
	school = School.BLOOD


func on_attack(target: Unit) -> void:
	if target.is_alive() and get_energy() >= 2:
		drain(target, 1)
