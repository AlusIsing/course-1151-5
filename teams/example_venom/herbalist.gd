extends Healer
## 草藥師（補師，沒有流派）：每回合幫相鄰的隊友回 3 血；自己被打時用能量幫自己回血。
## 花費 = 10 + 2 × 3 = 16 點


func _init() -> void:
	unit_name = "草藥師"
	max_hp = 10
	attack = 3
	color = Color("#f8bbd0")
	grid_position = Vector2i(0, 1)   # 中排左


func on_hurt(_amount: int, _source: Unit) -> void:
	if get_energy() > 0:
		heal(self, mini(3, get_energy()))
