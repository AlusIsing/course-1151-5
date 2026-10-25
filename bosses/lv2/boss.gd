extends Boss
## Lv2 刺甲龜
## HP 70 / ATK 4
## 能力「尖刺」：被普攻打中時，把那次傷害全額反彈給攻擊牠的角色。
##             技能、毒造成的傷害不會被反彈。
## 弱點：用技能打牠（deal_damage、poison……）。


func _init() -> void:
	super()
	unit_name = "刺甲龜"
	max_hp = 70
	attack = 4
	color = Color("#5d8a66")


func on_attacked(amount: int, attacker: Unit) -> void:
	if amount > 0 and attacker != null and attacker.is_alive():
		say("尖刺！")
		deal_damage(attacker, amount)
