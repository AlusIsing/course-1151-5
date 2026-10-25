extends "bone_archer_left.gd"
## 骨弓手（死靈）：和左邊那隻一樣，只是站後排右。
## 花費 = 7 + 2 × 4 = 15 點


func _init() -> void:
	super()
	grid_position = Vector2i(2, 2)   # 後排右
