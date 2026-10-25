extends Unit
## 範例角色：史萊姆
## 只有數值、沒有技能。試著改改看血量和攻擊！
## 花費 = max_hp + 2 × attack = 12 + 2 × 3 = 18 點


func _init() -> void:
	unit_name = "史萊姆"
	max_hp = 12
	attack = 3
	color = Color("#7ed957")
