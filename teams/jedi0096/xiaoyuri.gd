extends "venom_mage.gd"
## 小yuri（劇毒法師）：冰晶琉璃的琉璃，站在 zyzy0826 前面。
## 花費 = 18 + 2 × 1 = 20 點


func _init() -> void:
	unit_name = "小yuri"
	max_hp = 18
	attack = 1                       # 至少 1 才會普攻、觸發 on_attack
	color = Color("#f8bbd0")
	grid_position = Vector2i(1, 0)   # 前排中
	school = School.VENOM
