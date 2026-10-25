extends Assassin
## 範例角色：影刃（刺客）
## 繞過前排，直接打敵方最後排。
## 花費 = 10 + 2 × 5 = 20 點


func _init() -> void:
	unit_name = "影刃"
	max_hp = 10
	attack = 5
	color = Color("#546e7a")
	grid_position = Vector2i(0, 2)   # 後排左
