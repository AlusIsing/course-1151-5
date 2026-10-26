extends Warrior
## 你的第一隻角色：改職業、名字、數值和站位看看
## 花費 = max_hp + 2 × attack = 10 + 2 × 2 = 14 點


func _init() -> void:
	unit_name = "新兵"
	max_hp = 10
	attack = 2
	grid_position = Vector2i(1, 0)   # 前排中
