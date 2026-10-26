extends "venom_mage.gd"
## 小黑（劇毒法師）：黑白雙煞的弟弟，站在 zyzy0826 左邊。
## 花費 = 18 + 2 × 1 = 20 點


func _init() -> void:
	unit_name = "小黑"
	max_hp = 18
	attack = 1                       # 至少 1 才會普攻、觸發 on_attack
	color = Color("#212121")
	grid_position = Vector2i(0, 1)   # 中排左
	school = School.VENOM
