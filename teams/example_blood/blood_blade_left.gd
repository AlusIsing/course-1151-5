extends Assassin
## 血影刺客（狂血）：繞過前排打後排，血少的時候能量全部拿來吸血。
## 花費 = 8 + 2 × 4 = 16 點


func _init() -> void:
	unit_name = "血影刺客"
	max_hp = 8
	attack = 4
	color = Color("#c62828")
	grid_position = Vector2i(0, 1)   # 中排左
	school = School.BLOOD


func on_attack(target: Unit) -> void:
	if not target.is_alive():
		return
	if hp * 2 < max_hp and get_energy() >= 4:
		drain(target, 2)
	elif get_energy() >= 2:
		drain(target, 1)
