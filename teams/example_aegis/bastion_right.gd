extends "bastion_left.gd"
## 堡壘（聖盾坦克）：和左邊那隻一樣，只是站前排右。
## 花費 = 24 + 2 × 2 = 28 點


func _init() -> void:
	super()
	grid_position = Vector2i(2, 0)   # 前排右
