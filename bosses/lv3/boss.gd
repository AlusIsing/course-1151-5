extends Boss
## Lv3 雷神
## HP 120 / ATK 5
## 能力「雷擊」：第 3、6、9…回合蓄力，這回合不攻擊，而且受到的傷害 ×2。
##             蓄力的下一回合，攻擊會打穿整排，每隻角色受到 8 點傷害。
## 弱點：蓄力那回合。

var charging := false


func _init() -> void:
	super()
	unit_name = "雷神"
	max_hp = 120
	attack = 5
	color = Color("#7e57c2")


func on_round_start(round_number: int) -> void:
	skip_attack = false
	pierce = false
	damage_taken_multiplier = 1
	status_text = ""
	if charging:
		charging = false
		pierce = true
		pierce_damage = 8
		status_text = "雷擊！"
		say("雷擊！")
	elif round_number % 3 == 0:
		charging = true
		skip_attack = true
		damage_taken_multiplier = 2
		status_text = "蓄力中（受傷 ×2）"
		say("開始蓄力……")
