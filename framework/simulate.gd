extends SceneTree
## 無畫面模擬，講師調數值用：
##   godot --headless --script res://framework/simulate.gd                  # my_team 打它 formation.json 記的 Boss
##   godot --headless --script res://framework/simulate.gd -- example       # 指定隊伍
##   godot --headless --script res://framework/simulate.gd -- example lv3   # 指定隊伍和 Boss


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	MatchSetup.team_name = args[0] if args.size() >= 1 else Rules.DEFAULT_TEAM
	MatchSetup.boss_key = args[1] if args.size() >= 2 else ""
	var player: Formation = MatchSetup.player_formation()
	var boss_key: String = MatchSetup.resolve_boss(player)

	var errors: Array[String] = []
	if not Rules.BOSSES.has(boss_key):
		errors.append("Boss 要是 %s 其中一個，現在是 \"%s\"" % [", ".join(Rules.BOSSES.keys()), boss_key])
	else:
		errors = Validator.check_formation(player)
	var enemy: Formation = Formation.load_dir(Rules.BOSSES.get(boss_key, ""))
	if errors.is_empty():
		errors.append_array(Validator.check_cells(enemy))
	if not errors.is_empty():
		for error: String in errors:
			print("✗ ", error)
		quit(1)
		return

	var battle: Battle = Battle.new(player, enemy)
	var tags: RegEx = RegEx.create_from_string(r"\[/?(b|i|u|color)(=[^\]]*)?\]")
	battle.logged.connect(func(text: String) -> void:
		print(tags.sub(text, "", true).replace("[lb]", "[").replace("[rb]", "]")))
	print("%s vs %s：%s" % [MatchSetup.team_name, boss_key, Validator.describe_cost(player.load_scripts())])
	battle.start()
	while battle.result == "":
		battle.step()

	for unit: Unit in battle.roster:
		unit.free()
	quit(0 if battle.result == "win" else 2)
