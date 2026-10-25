extends Mage
## 毒霧法師（劇毒）：打整行，攻擊後幫第一個目標疊一層毒。
## 花費 = 10 + 2 × 2 = 14 點


func _init() -> void:
	unit_name = "毒霧法師"
	max_hp = 10
	attack = 2
	color = Color("#9ccc65")
	grid_position = Vector2i(1, 1)   # 中排中（在坦克後面）
	school = School.VENOM


func on_attack(target: Unit) -> void:
	poison(target, 1, 3)
