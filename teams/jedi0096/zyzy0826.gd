extends Tank
## zyzy0826（劇毒坦克）：站正中央，上下左右四隻隊友受傷時分擔一半（毒傷也算）。
## 花費 = 20 + 2 × 0 = 20 點


func _init() -> void:
	unit_name = "zyzy0826"
	max_hp = 20
	attack = 0
	color = Color("#455a64")
	grid_position = Vector2i(1, 1)   # 中排中
	school = School.VENOM


func on_battle_start() -> void:
	say("全員就位！今天誰也別想越過我。")
