extends Team
## 五毒法師：5 隻劇毒法師，開場就疊毒，雷神第 3 回合毒發倒下


func _init() -> void:
	team_name = "我打贏 Jedi 當副召"
	github = "huangtank"            # 要和資料夾名稱一樣
	members = [
		preload("toad.gd"),
		preload("viper.gd"),
		preload("scorpion.gd"),
		preload("spider.gd"),
		preload("centipede.gd"),
	]
