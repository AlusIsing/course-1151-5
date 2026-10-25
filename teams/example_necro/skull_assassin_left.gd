extends Assassin
## 骷髏刺客（死靈）：衝去打後排；死的時候詛咒後排再補刀。
## 花費 = 7 + 2 × 4 = 15 點


func _init() -> void:
	unit_name = "骷髏刺客"
	max_hp = 7
	attack = 4
	color = Color("#757575")
	grid_position = Vector2i(0, 0)   # 前排左
	school = School.NECRO


func on_attack(target: Unit) -> void:
	if target.is_alive() and get_energy() >= 6:
		curse(target, 3)


func on_death() -> void:
	var enemies: Array[Unit] = get_enemies()
	if enemies.is_empty():
		return
	var target: Unit = enemies[-1]           # 最後排
	curse(target, 4)
	deal_damage(target, 5)
	if target.is_alive() and get_energy() > 0:
		deal_damage(target, mini(5, get_energy()))
