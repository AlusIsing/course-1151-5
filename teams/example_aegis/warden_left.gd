extends Healer
## 守護者（聖盾補師）：每回合幫相鄰隊友回 2 血；被打的時候把能量全部拿來給自己上盾。
## 花費 = 10 + 2 × 2 = 14 點


func _init() -> void:
	unit_name = "守護者"
	max_hp = 10
	attack = 2
	color = Color("#e3f2fd")
	grid_position = Vector2i(0, 1)   # 中排左
	school = School.AEGIS


func on_hurt(_amount: int, _source: Unit) -> void:
	if get_energy() > 0:
		shield(self, get_energy())


func on_ally_death(_ally: Unit) -> void:
	var weakest: Unit = self
	for ally: Unit in get_allies():
		if ally.hp < weakest.hp:
			weakest = ally
	if get_energy() > 0:
		shield(weakest, get_energy())
