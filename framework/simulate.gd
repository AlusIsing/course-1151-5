extends SceneTree
## 無畫面模擬，調數值用：
##   godot --headless --script res://framework/simulate.gd                  # example 打木樁
##   godot --headless --script res://framework/simulate.gd -- 帳號          # 指定隊伍（teams/ 底下的資料夾）
##   godot --headless --script res://framework/simulate.gd -- 帳號 lv3      # 指定隊伍和 Boss


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var github: String = args[0] if args.size() >= 1 else Rules.DEFAULT_TEAM
	var boss_key: String = args[1] if args.size() >= 2 else Rules.DEFAULT_BOSS

	var errors: Array[String] = []
	if not Rules.BOSSES.has(boss_key):
		errors.append("Boss 要是 %s 其中一個，現在是 \"%s\"" % [", ".join(Rules.BOSSES.keys()), boss_key])
	else:
		errors = Validator.check_team_folder(github)
	if not errors.is_empty():
		for error: String in errors:
			print("✗ ", error)
		quit(1)
		return

	var team: Team = Team.load_folder(github)
	var battle: Battle = Battle.new(team.members, [load(Rules.BOSSES[boss_key]) as Script])
	print("%s vs %s：%s" % [team.label(), boss_key, Validator.describe_cost(team.members)])
	_play(battle)
	quit(0 if battle.result == "win" else 2)


func _play(battle: Battle) -> void:
	var tags: RegEx = RegEx.create_from_string(r"\[/?(b|i|u|color)(=[^\]]*)?\]")
	battle.logged.connect(func(text: String) -> void:
		print(tags.sub(text, "", true).replace("[lb]", "[").replace("[rb]", "]")))
	battle.start()
	while battle.result == "":
		battle.step()
	for unit: Unit in battle.roster:
		unit.free()
