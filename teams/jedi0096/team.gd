extends Team
## 🧪 劇毒 5 隻：黑白雙煞、冰晶琉璃 4 隻劇毒法師，隊長 zyzy0826 站正中央掩護。
## 劇毒 2 隻：毒傷每回合 +2；4 隻：中毒的敵人無法被治療。


func _init() -> void:
	team_name = "黑白冰晶"
	github = "jedi0096"            # 要和資料夾名稱一樣
	members = [
		preload("zyzy0826.gd"),
		preload("xiaohei.gd"),
		preload("xiaobai.gd"),
		preload("xiaoyuri.gd"),
		preload("xiaobing.gd"),
	]
