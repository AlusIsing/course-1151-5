extends Tank
## 守墓人（坦克，沒有流派）：站前排中間，替兩隻骷髏刺客分擔傷害，讓牠們慢一點死。
## 花費 = 38 + 2 × 1 = 40 點


func _init() -> void:
	unit_name = "守墓人"
	max_hp = 38
	attack = 1
	color = Color("#5d4037")
	grid_position = Vector2i(1, 0)   # 前排中
