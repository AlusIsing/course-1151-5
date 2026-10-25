extends "berserker_left.gd"
## 狂戰士（狂血）：和左邊那隻一樣，只是站前排右。
## 花費 = 18 + 2 × 4 = 26 點


func _init() -> void:
	super()
	grid_position = Vector2i(2, 0)   # 前排右
