extends Team
## 💀 死靈 4 隻 + 坦克。血少的射手和刺客平常存能量，死的時候加上 5 點靈魂能量一次放大招。
## 死靈 2 隻：死亡時有 5 點靈魂能量；4 隻：死亡時對全體敵人造成 1 點傷害。
## 這個資料夾是流派範例，tools/balance.gd 會拿它和其他流派範例對戰。


func _init() -> void:
	team_name = "死靈範例隊"
	github = "example_necro"
	members = [
		preload("skull_assassin_left.gd"),
		preload("gravekeeper.gd"),
		preload("skull_assassin_right.gd"),
		preload("bone_archer_left.gd"),
		preload("bone_archer_right.gd"),
	]
