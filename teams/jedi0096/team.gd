extends Team
## 你的隊伍：把 github 改成你的帳號，再把角色加進 members


func _init() -> void:
	team_name = "zyzy0826"
	github = "jedi0096"            # 要和資料夾名稱一樣
	members = [
		preload("zyzy0826.gd"),
		preload("xiaohei.gd"),
		preload("xiaobai.gd"),
		preload("xiaobing.gd"),
		preload("xiaoyuri.gd"),
	]
