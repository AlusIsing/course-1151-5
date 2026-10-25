extends Tank
## 肉盾（坦克，沒有流派）：站在兩隻狂戰士中間替他們分擔傷害。
## 花費 = 14 + 2 × 1 = 16 點


func _init() -> void:
	unit_name = "肉盾"
	max_hp = 14
	attack = 1
	color = Color("#b0bec5")
	grid_position = Vector2i(1, 0)   # 前排中
