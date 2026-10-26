
extends Team
## 💀 死靈 5 隻：黑白雙煞、冰晶琉璃，隊長 zyzy0826。
## 死靈 2 隻：倒下時得 6 點靈魂能量；4 隻：倒下時對全體敵人造成 1 點傷害。

   
func _init() -> void:
	team_name = "MAX"
	github = "jedi0096"            # 要和資料夾名稱一樣
	members = [
		preload("XiaoNas.gd"),
		preload("xinshoutw.gd"),
		preload("typec.gd"),
		preload("alus.gd"),
		preload("red.gd"),
	]
