extends "blood_blade_left.gd"
## 血影刺客（狂血）：和左邊那隻一樣，只是站中排右。
## 花費 = 10 + 2 × 3 = 16 點


func _init() -> void:
	super()
	grid_position = Vector2i(2, 1)   # 中排右
