extends Tank
## 毒沼坦克（劇毒）：站前排拖時間，打到誰就毒誰。
## 花費 = 34 + 2 × 1 = 36 點


func _init() -> void:
	unit_name = "毒沼坦克"
	max_hp = 34
	attack = 1
	color = Color("#558b2f")
	grid_position = Vector2i(1, 0)   # 前排中
	school = School.VENOM


func on_attack(target: Unit) -> void:
	# 毒持續 3 回合；能量有 6 點就下 2 點的毒，把能量用完
	if get_energy() >= 6:
		poison(target, 2, 3)
	elif get_energy() >= 3:
		poison(target, 1, 3)
