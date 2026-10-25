extends Team
## 🛡️ 聖盾 4 隻 + 射手。兩隻坦克、兩隻補師一直補盾，目標是撐到時間到、比剩餘血量。
## 聖盾 4 隻：開場全隊 6 點護盾。
## 這個資料夾是流派範例，tools/balance.gd 會拿它和其他流派範例對戰。


func _init() -> void:
	team_name = "聖盾範例隊"
	github = "example_aegis"
	members = [
		preload("bastion_left.gd"),
		preload("bastion_right.gd"),
		preload("warden_left.gd"),
		preload("warden_right.gd"),
		preload("lookout.gd"),
	]
