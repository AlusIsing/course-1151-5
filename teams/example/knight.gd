extends Unit
## 範例角色：騎士
## 技能「追擊」：每次攻擊之後，再對同一個目標補 1 點傷害。
## 花費 = 20 + 2 × 4 = 28 點


func _init() -> void:
	unit_name = "騎士"
	max_hp = 20
	attack = 4
	color = Color("#8fa3c7")


func on_attack(target: Unit) -> void:
	deal_damage(target, 1)
