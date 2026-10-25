extends SceneTree
## Boss 難度檢查（講師用）：確認「只有數值、沒有技能」的隊伍打不贏該擋住它們的 Boss。
##
##   godot --headless --script res://tools/boss_check.gd
##   godot --headless --script res://tools/boss_check.gd -- --random=2000 帳號A 帳號B
##
## 1. 純數值隊伍：幾種常見組法 + 隨機產生的隊伍（職業、數值、站位、隻數都隨機，花滿預算）
## 2. 有技能的隊伍：teams/ 底下的資料夾（預設是範例隊伍）
## 印出每隻 Boss 被純數值隊伍打贏的比例、打贏的組法，以及有技能的隊伍的戰績。

const ROLES: Array[String] = ["Warrior", "Tank", "Archer", "Mage", "Healer", "Assassin"]
const DEFAULT_TEAMS: Array[String] = ["example", "example_venom", "example_aegis", "example_blood", "example_necro"]
const DEFAULT_RANDOM := 1000
const SHOW_WINNERS := 3

## 常見的純數值組法：[職業, max_hp, attack, 行, 排]
const PRESETS := {
	"範例隊拿掉技能": [["Warrior", 20, 4, 0, 0], ["Tank", 30, 1, 1, 0], ["Healer", 12, 2, 1, 1], ["Archer", 10, 4, 1, 2]],
	"坦克 + 三射手": [["Tank", 40, 0, 1, 0], ["Archer", 6, 7, 0, 1], ["Archer", 6, 7, 1, 1], ["Archer", 6, 7, 2, 1]],
	"三戰士 + 射手": [["Warrior", 13, 6, 0, 0], ["Warrior", 13, 6, 1, 0], ["Warrior", 13, 6, 2, 0], ["Archer", 13, 6, 1, 1]],
	"五射手": [["Archer", 4, 8, 0, 0], ["Archer", 4, 8, 1, 0], ["Archer", 4, 8, 2, 0], ["Archer", 4, 8, 0, 1], ["Archer", 4, 8, 1, 1]],
	"坦克 + 補師 + 三射手": [["Tank", 30, 1, 1, 0], ["Healer", 8, 4, 1, 1], ["Archer", 8, 6, 0, 1], ["Archer", 8, 6, 2, 1], ["Archer", 8, 2, 1, 2]],
	"兩坦克 + 兩補師 + 射手": [["Tank", 30, 0, 0, 0], ["Tank", 30, 0, 2, 0], ["Healer", 5, 5, 0, 1], ["Healer", 5, 5, 2, 1], ["Archer", 4, 3, 1, 1]],
	"五法師": [["Mage", 10, 5, 0, 0], ["Mage", 10, 5, 1, 0], ["Mage", 10, 5, 2, 0], ["Mage", 10, 5, 0, 1], ["Mage", 10, 5, 1, 1]],
}

var _scripts: Dictionary = {}     # 原始碼 -> GDScript，同樣的角色不用重新編譯


func _init() -> void:
	var random_count: int = DEFAULT_RANDOM
	var teams: Array[String] = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--random="):
			random_count = maxi(0, arg.trim_prefix("--random=").to_int())
		else:
			teams.append(arg)
	if teams.is_empty():
		teams = DEFAULT_TEAMS.duplicate()

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = Rules.SEED
	var lineups: Dictionary = {}     # 名稱 -> Array[Script]
	for preset_name: String in PRESETS:
		lineups[preset_name] = _build(PRESETS[preset_name])
	for i: int in random_count:
		var spec: Array = _random_spec(rng)
		lineups["隨機 #%d %s" % [i + 1, _describe(spec)]] = _build(spec)

	print("## 純數值隊伍（%d 種常見組法 + %d 支隨機隊伍）" % [PRESETS.size(), random_count])
	print("")
	print("| Boss | 打贏的隊伍 | 常見組法 |")
	print("|---|---|---|")
	var winners: Dictionary = {}
	for boss_key: String in Rules.BOSSES:
		var boss: Script = load(Rules.BOSSES[boss_key]) as Script
		var won: Array[String] = []
		var preset_results: Array[String] = []
		for lineup_name: String in lineups:
			var win: bool = _fight(lineups[lineup_name], boss)
			if win:
				won.append(lineup_name)
			if PRESETS.has(lineup_name):
				preset_results.append("%s%s" % ["✅" if win else "❌", lineup_name])
		winners[boss_key] = won
		print("| %s | %d / %d（%d%%） | %s |" % [boss_key, won.size(), lineups.size(),
				roundi(100.0 * won.size() / lineups.size()), "　".join(preset_results)])
	for boss_key: String in Rules.BOSSES:
		var won: Array = winners[boss_key]
		if boss_key != "dummy" and not won.is_empty():
			print("")
			print("打贏 %s 的例子：" % boss_key)
			for lineup_name: String in won.slice(0, SHOW_WINNERS):
				print("- ", lineup_name)

	print("")
	print("## 有技能的隊伍")
	print("")
	print("| 隊伍 | %s |" % " | ".join(Rules.BOSSES.keys()))
	print("|---|%s" % "---|".repeat(Rules.BOSSES.size()))
	# 常見組法加上最基本的技能：攻擊後花 3 能量補一刀、補師受傷時幫自己回血（數值完全一樣）
	for preset_name: String in PRESETS:
		_print_record("%s ＋基礎技能" % preset_name, _build(PRESETS[preset_name], true))
	for github: String in teams:
		if not Validator.check_team_folder(github).is_empty():
			print("| %s | 沒有通過檢查 |" % github)
			continue
		_print_record(github, Team.load_folder(github).members)
	quit(0)


func _print_record(label: String, members: Array[Script]) -> void:
	var cells: Array[String] = []
	for boss_key: String in Rules.BOSSES:
		var battle: Battle = _battle(members, load(Rules.BOSSES[boss_key]) as Script)
		cells.append("%s 第 %d 回合" % ["✅" if battle.result == "win" else "❌", battle.round_number])
		_free(battle)
	print("| %s | %s |" % [label, " | ".join(cells)])


func _fight(members: Array[Script], boss: Script) -> bool:
	var battle: Battle = _battle(members, boss)
	var win: bool = battle.result == "win"
	_free(battle)
	return win


func _battle(members: Array[Script], boss: Script) -> Battle:
	var battle: Battle = Battle.new(members, [boss])
	battle.start()
	while battle.result == "":
		battle.step()
	return battle


func _free(battle: Battle) -> void:
	for unit: Unit in battle.roster:
		unit.free()


## 隨機的純數值隊伍：1–5 隻，花滿預算（不超過數值上限），站不同格
func _random_spec(rng: RandomNumberGenerator) -> Array:
	var count: int = rng.randi_range(1, Rules.MAX_UNITS)
	var cells: Array[Vector2i] = []
	for row: int in Rules.GRID_ROWS:
		for col: int in Rules.GRID_COLS:
			cells.append(Vector2i(col, row))
	var spec: Array = []
	var budget_left: int = Rules.BUDGET
	for i: int in count:
		var share: int = budget_left / (count - i)
		var attack: int = rng.randi_range(Rules.ATTACK_MIN, mini(Rules.ATTACK_MAX, (share - 1) / Rules.ATTACK_COST))
		var max_hp: int = clampi(share - attack * Rules.ATTACK_COST, Rules.MAX_HP_MIN, Rules.MAX_HP_MAX)
		budget_left -= Rules.unit_cost(max_hp, attack)
		var cell: Vector2i = cells.pop_at(rng.randi_range(0, cells.size() - 1))
		spec.append([ROLES[rng.randi_range(0, ROLES.size() - 1)], max_hp, attack, cell.x, cell.y])
	return spec


func _describe(spec: Array) -> String:
	var parts: Array[String] = []
	for entry: Array in spec:
		parts.append("%s(%d,%d)血%d攻%d" % [entry[0], entry[3], entry[4], entry[1], entry[2]])
	return " ".join(parts)


## 把 [職業, max_hp, attack, 行, 排] 變成角色腳本；skills = false 時完全沒有技能
func _build(spec: Array, skills: bool = false) -> Array[Script]:
	var scripts: Array[Script] = []
	for entry: Array in spec:
		var source: String = "extends %s\n\nfunc _init() -> void:\n\tunit_name = \"%s\"\n\tmax_hp = %d\n\tattack = %d\n\tgrid_position = Vector2i(%d, %d)\n" \
				% [entry[0], entry[0], entry[1], entry[2], entry[3], entry[4]]
		if skills:
			source += "\nfunc on_attack(target: Unit) -> void:\n\tif target.is_alive() and get_energy() >= 3:\n\t\tdeal_damage(target, 3)\n"
			source += "\nfunc on_hurt(_amount: int, _source: Unit) -> void:\n\tif get_role() == \"補師\" and is_alive() and get_energy() >= 3:\n\t\theal(self, 3)\n"
		if not _scripts.has(source):
			var script: GDScript = GDScript.new()
			script.source_code = source
			script.reload()
			_scripts[source] = script
		scripts.append(_scripts[source])
	return scripts
