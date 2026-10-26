extends Team
## 你的隊伍：把 github 改成你的帳號，再把角色加進 members


func _init() -> void:
	team_name = "我的隊伍"
	github = "template"            # 要和資料夾名稱一樣
	members = [
		preload("my_unit.gd"),
	]
