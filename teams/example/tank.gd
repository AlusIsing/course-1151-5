extends Tank
## 範例角色：盾兵（坦克）
## 站在隊友旁邊，替他們分擔一半的傷害。
## 花費 = 30 + 2 × 1 = 32 點


func _init() -> void:
	unit_name = "盾兵"
	max_hp = 30
	attack = 1
	color = Color("#b0bec5")
	grid_position = Vector2i(1, 0)   # 前排中
