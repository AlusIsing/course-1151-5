extends Team
## 🔥 狂血 4 隻 + 坦克。戰士和刺客衝進去換血，能量拿來吸血。
## 狂血 2 隻：普攻命中後回 1 血；4 隻：血量低於一半時攻擊 +2。
## 這個資料夾是流派範例，tools/balance.gd 會拿它和其他流派範例對戰。


func _init() -> void:
	team_name = "狂血範例隊"
	github = "example_blood"
	members = [
		preload("berserker_left.gd"),
		preload("meat_shield.gd"),
		preload("berserker_right.gd"),
		preload("blood_blade_left.gd"),
		preload("blood_blade_right.gd"),
	]
