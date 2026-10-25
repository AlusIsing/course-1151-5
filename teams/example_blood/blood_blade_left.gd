extends Assassin
## 血影刺客（狂血）：繞過前排打後排，血少的時候能量全部拿來吸血。
## 花費 = 10 + 2 × 3 = 16 點


func _init() -> void:
	unit_name = "血影刺客"
	max_hp = 10
	attack = 3
	color = Color("#c62828")
	grid_position = Vector2i(0, 1)   # 中排左
	school = School.BLOOD


func on_attack(target: Unit) -> void:
	# 能量全部拿來吸血（每 1 點傷害花 2 能量）
	if target.is_alive() and get_energy() >= 2:
		drain(target, get_energy() / 2)
