extends "venom_mage.gd"
## 小白（劇毒法師）：黑白雙煞的哥哥，站在 zyzy0826 右邊。
## 花費 = 18 + 2 × 1 = 20 點


func _init() -> void:
	unit_name = "小白"
	max_hp = 18
	attack = 1                       # 至少 1 才會普攻、觸發 on_attack
	color = Color("#fafafa")
	grid_position = Vector2i(2, 1)   # 中排右
	school = School.VENOM
