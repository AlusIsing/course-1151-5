extends SceneTree
## 無畫面模擬，講師調數值用：
##   godot --headless --script res://framework/simulate.gd            # 用 team.gd 設定的 Boss
##   godot --headless --script res://framework/simulate.gd -- lv3     # 指定 Boss


func _init() -> void:
	var team := (load(Rules.TEAM_PATH) as Script).get_script_constant_map()
	var members: Array = team.get("MEMBERS", [])
	var args := OS.get_cmdline_user_args()
	var boss_key: String = args[0] if not args.is_empty() else team.get("BOSS", "dummy")

	var errors := Validator.check_team(members)
	if not errors.is_empty():
		for error in errors:
			print("✗ ", error)
		quit(1)
		return

	var battle := Battle.new(members, load(Rules.BOSSES[boss_key]))
	var tags := RegEx.create_from_string(r"\[/?[^\]]+\]")
	battle.logged.connect(func(text: String) -> void: print(tags.sub(text, "", true)))
	print(Validator.describe_cost(members))
	battle.start()
	while battle.result == "":
		battle.step()

	for unit in battle.roster:
		unit.free()
	quit(0 if battle.result == "win" else 2)
