extends Healer
## 範例角色：修女（補師）
## 每回合幫相鄰有受傷的隊友回 2 血；自己被打的時候說句話。
## 花費 = 12 + 2 × 2 = 16 點


func _init() -> void:
	unit_name = "修女"
	max_hp = 12
	attack = 2
	color = Color("#f8bbd0")
	grid_position = Vector2i(1, 1)   # 中排中


func on_hurt(_amount: int, _source: Unit) -> void:
	say("好痛……")
