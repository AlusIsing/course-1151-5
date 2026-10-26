
extends Team
## 🔥 狂血 2 隻：XiaoNas、typec（普攻命中後回血）
## 🛡️ 聖盾 3 隻：red、Alus、xinshoutw（開場全隊 3 點護盾），隊長 red。

   
func _init() -> void:
	team_name = "MAX"
	github = "jedi0096_MAX"        # 要和資料夾名稱一樣
	members = [
		preload("XiaoNas.gd"),
		preload("xinshoutw.gd"),
		preload("typec.gd"),
		preload("alus.gd"),
		preload("red.gd"),
	]
