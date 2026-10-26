extends Archer
## 補刀弓手（射手）：普攻只有 1 點，攻擊之後再用技能補 3 點傷害。
## 技能傷害不會被刺甲龜反彈，每回合回 3 能量剛好夠用一次。
## 花費 = 14 + 2 × 1 = 16 點


func _init() -> void:
	unit_name = "補刀弓手"
	max_hp = 14
	attack = 1
	color = Color("#ffcc80")
	grid_position = Vector2i(1, 1)   # 中排中


func on_attack(target: Unit) -> void:
	if target.is_alive():
		deal_damage(target, 3)
