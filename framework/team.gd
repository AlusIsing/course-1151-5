class_name Team
extends RefCounted
## 一支隊伍。每個人在 teams/<GitHub 帳號>/team.gd 寫一個：
##
##     extends Team
##
##     func _init() -> void:
##         team_name = "火鍋隊"
##         github = "你的 GitHub 帳號"
##         members = [
##             preload("knight.gd"),
##             preload("archer.gd"),
##         ]
##
## 每隻角色站哪一格，寫在角色自己的 _init() 裡（grid_position）。

const FILE_NAME := "team.gd"

var team_name: String = ""
var github: String = ""             # 要和資料夾名稱一樣
var members: Array[Script] = []     # 最多 5 隻，總預算 100 點


static func path_of(github_name: String) -> String:
	return "%s/%s" % [Rules.team_dir(github_name), FILE_NAME]


## 讀 teams/<github_name>/team.gd，讀不到就回傳 null。
## 會執行學員的程式，一定要先通過 Validator.check_team_folder()
static func load_folder(github_name: String) -> Team:
	var path: String = path_of(github_name)
	if not ResourceLoader.exists(path):
		return null
	var script: Script = load(path) as Script
	if script == null or not script.can_instantiate():
		return null
	var instance: Object = script.new()
	return instance as Team


## 顯示用的名字，例如「範例隊（example）」
func label() -> String:
	return "%s（%s）" % [team_name if team_name != "" else "未命名", github]
