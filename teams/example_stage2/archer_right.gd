extends "archer.gd"
## 和 archer.gd 一樣，只改站位。


func _init() -> void:
	super()                          # 先用 archer.gd 的設定
	grid_position = Vector2i(2, 1)   # 中排右
