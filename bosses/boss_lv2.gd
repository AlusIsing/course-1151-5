extends Boss
## Lv2 刺甲龜
## HP 70 / ATK 4
## 能力「尖刺」：每次受到傷害，把一半的傷害（無條件捨去）反彈給攻擊牠的角色。
##             技能造成的傷害也會被反彈。


func _init() -> void:
	unit_name = "刺甲龜"
	max_hp = 70
	attack = 4
	color = Color("#5d8a66")


func on_hurt(amount: int, source: Unit) -> void:
	var reflected := floori(amount / 2.0)
	if reflected > 0 and source != null and source != self and source.is_alive():
		deal_damage(source, reflected)
