extends Mage
## 範例角色：見習法師（法師）
## 一次打中敵方同一行的所有角色。
## 花費 = 10 + 2 × 3 = 16 點


func _init() -> void:
	unit_name = "見習法師"
	max_hp = 10
	attack = 3
	color = Color("#9575cd")
