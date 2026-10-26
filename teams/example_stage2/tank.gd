extends Tank
## 盾兵（坦克）：站前排中間擋 Boss，替旁邊的弓手分擔傷害。
## attack 設 0：普攻打不痛，刺甲龜也反彈不了。
## 花費 = 30 + 2 × 0 = 30 點


func _init() -> void:
	unit_name = "盾兵"
	max_hp = 30
	attack = 0
	color = Color("#b0bec5")
	grid_position = Vector2i(1, 0)   # 前排中
