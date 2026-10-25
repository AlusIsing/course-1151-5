extends Mage
## 毒霧法師（劇毒）：打整行，攻擊後幫第一個目標疊一層毒。
## 花費 = 10 + 2 × 2 = 14 點


func _init() -> void:
	unit_name = "毒霧法師"
	max_hp = 10
	attack = 2
	color = Color("#9ccc65")
	grid_position = Vector2i(1, 1)   # 中排中（在坦克後面）
	school = School.VENOM


func on_attack(target: Unit) -> void:
	# 毒持續 3 回合；能量有 6 點就下 2 點的毒，把能量用完
	if get_energy() >= 6:
		poison(target, 2, 3)
	elif get_energy() >= 3:
		poison(target, 1, 3)
