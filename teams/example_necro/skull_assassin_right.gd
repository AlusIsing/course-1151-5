extends "skull_assassin_left.gd"
## 骷髏刺客（死靈）：和左邊那隻一樣，只是站前排右。
## 花費 = 7 + 2 × 4 = 15 點


func _init() -> void:
	super()
	grid_position = Vector2i(2, 0)   # 前排右
