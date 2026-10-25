extends Team
## 範例隊伍。複製整個資料夾、改成自己的 GitHub 帳號，就是你的隊伍。
## 這個資料夾還有沒上場的史萊姆、見習法師、影刃，可以換進 members 試試看。


func _init() -> void:
	team_name = "範例隊"
	github = "example"
	members = [
		preload("knight.gd"),
		preload("tank.gd"),
		preload("healer.gd"),
		preload("archer.gd"),
	]
