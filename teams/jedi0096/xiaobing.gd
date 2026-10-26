extends "venom_mage.gd"
## 小冰（劇毒法師）：冰晶琉璃的冰晶，站在 zyzy0826 後面。
## 花費 = 18 + 2 × 1 = 20 點


func _init() -> void:
	unit_name = "小冰"
	max_hp = 18
	attack = 1                       # 至少 1 才會普攻、觸發 on_attack
	color = Color("#81d4fa")
	grid_position = Vector2i(1, 2)   # 後排中
	school = School.VENOM
