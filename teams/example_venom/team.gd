extends Team
## 🧪 劇毒 4 隻 + 補師。射手和法師在後排一直上毒，坦克在前排拖時間。
## 劇毒 2 隻：毒傷每回合 +1；4 隻：中毒的敵人無法被治療。
## 這個資料夾是流派範例，tools/balance.gd 會拿它和其他流派範例對戰。


func _init() -> void:
	team_name = "劇毒範例隊"
	github = "example_venom"
	members = [
		preload("swamp_tank.gd"),
		preload("herbalist.gd"),
		preload("miasma_mage.gd"),
		preload("viper_archer_left.gd"),
		preload("viper_archer_right.gd"),
	]
