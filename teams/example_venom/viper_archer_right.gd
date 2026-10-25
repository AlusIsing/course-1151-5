extends "viper_archer_left.gd"
## 毒蛇射手（劇毒）：和左邊那隻一樣，只是站後排右。
## 花費 = 10 + 2 × 2 = 14 點


func _init() -> void:
	super()
	grid_position = Vector2i(2, 2)   # 後排右
