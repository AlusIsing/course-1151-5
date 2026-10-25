extends Control
## 陣型預覽：讀 teams/<GitHub 帳號>/team.gd，把每隻角色畫在它 grid_position 的格子上。
## 只負責顯示和檢查，站位要在角色的 _init() 裡用程式寫。
## 改完程式切回遊戲視窗（或按「重新讀取」）就會更新。

## 一隻角色的數值，畫格子和清單用
class UnitInfo:
	var path: String
	var name: String
	var role: String
	var max_hp: int
	var attack: int
	var cost: int
	var school: int
	var color: Color
	var cell: Vector2i

@onready var team_select: OptionButton = %TeamSelect
@onready var boss_select: OptionButton = %BossSelect
@onready var reload_button: Button = %ReloadButton
@onready var budget_label: Label = %Budget
@onready var try_button: Button = %TryButton
@onready var tournament_button: Button = %TournamentButton
@onready var team_label: Label = %TeamLabel
@onready var member_list: VBoxContainer = %MemberList
@onready var board: GridContainer = %Board
@onready var status_label: RichTextLabel = %Status

var team_names: Array[String] = []
var boss_keys: Array[String] = []
var cells: Dictionary = {}          # Vector2i -> 那一格的 Label
var units: Array[UnitInfo] = []
var passed: bool = false


func _ready() -> void:
	_build_board()
	for key: String in Rules.BOSSES:
		boss_keys.append(key)
		boss_select.add_item("%s %s" % [key, _boss_name(key)])
	boss_select.select(maxi(0, boss_keys.find(MatchSetup.boss_key)))

	for dir_name: String in DirAccess.get_directories_at(Rules.TEAMS_DIR):
		if not dir_name.begins_with("."):
			team_names.append(dir_name)
	for team_name: String in team_names:
		team_select.add_item(team_name)
	if not team_names.has(MatchSetup.team):
		MatchSetup.team = Rules.DEFAULT_TEAM if team_names.has(Rules.DEFAULT_TEAM) else ""
		if MatchSetup.team == "" and not team_names.is_empty():
			MatchSetup.team = team_names[0]
	team_select.select(team_names.find(MatchSetup.team))

	team_select.item_selected.connect(func(index: int) -> void:
		MatchSetup.team = team_names[index]
		_reload())
	boss_select.item_selected.connect(func(index: int) -> void: MatchSetup.boss_key = boss_keys[index])
	reload_button.pressed.connect(_reload)
	try_button.pressed.connect(func() -> void:
		MatchSetup.mode = "boss"
		get_tree().change_scene_to_file(Rules.ARENA_SCENE))
	tournament_button.pressed.connect(func() -> void:
		MatchSetup.mode = "versus"
		get_tree().change_scene_to_file(Rules.ARENA_SCENE))
	_reload()


func _notification(what: int) -> void:
	# 在別的編輯器改完程式、切回遊戲視窗時自動重新讀取
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and is_node_ready():
		_reload()


# ---------------------------------------------------------------- 讀取

func _reload() -> void:
	units.clear()
	passed = false
	if MatchSetup.team == "":
		_show("", ["teams/ 底下還沒有隊伍資料夾"])
		return
	var dir: String = Rules.team_dir(MatchSetup.team)

	# 先只掃描程式碼；通過了才重新載入、執行學員的程式
	var errors: Array[String] = Validator.scan_folder(dir)
	if not errors.is_empty():
		_show(MatchSetup.team, errors)
		return
	_reload_scripts(dir, errors)
	if errors.is_empty():
		errors = Validator.check_team_folder(MatchSetup.team)
	passed = errors.is_empty()

	var team: Team = Team.load_folder(MatchSetup.team) if ResourceLoader.exists(Team.path_of(MatchSetup.team)) else null
	if team != null:
		for script: Script in team.members:
			var info: UnitInfo = _info(script)
			if info != null:
				units.append(info)
	_show(team.label() if team != null else MatchSetup.team, errors)


## 遊戲執行中改過的 .gd 不會自動更新，要手動重新編譯
func _reload_scripts(dir: String, errors: Array[String]) -> void:
	for path: String in Validator.gd_files(dir):
		if not ResourceLoader.has_cached(path):
			continue
		var script: GDScript = load(path) as GDScript
		var source: String = FileAccess.get_file_as_string(path)
		if script == null or script.source_code == source:
			continue
		script.source_code = source
		if script.reload() != OK:
			errors.append("%s 有語法錯誤，請看 Godot 編輯器下方的錯誤訊息" % path.trim_prefix("res://"))


func _info(script: Script) -> UnitInfo:
	if script == null or not script.can_instantiate():
		return null
	var instance: Object = script.new()
	var info: UnitInfo = null
	if instance is Unit:
		var unit: Unit = instance
		info = UnitInfo.new()
		info.path = script.resource_path
		info.name = unit.unit_name
		info.role = unit.get_role()
		info.max_hp = unit.max_hp
		info.attack = unit.attack
		info.cost = Rules.unit_cost(unit.max_hp, unit.attack)
		info.school = clampi(unit.school, 0, Rules.SCHOOL_NAMES.size() - 1)
		info.color = unit.color
		info.cell = unit.grid_position
	if instance is Node:
		(instance as Node).free()
	return info


func _boss_name(key: String) -> String:
	var script: Script = load(Rules.BOSSES[key]) as Script
	if script == null:
		return ""
	var boss: Unit = script.new()
	var boss_name: String = boss.unit_name
	boss.free()
	return boss_name


# ---------------------------------------------------------------- 畫面

func _build_board() -> void:
	board.columns = Rules.GRID_COLS + 1
	board.add_child(Control.new())
	for col: int in Rules.GRID_COLS:
		board.add_child(_header(Rules.COL_NAMES[col]))
	for row: int in Rules.GRID_ROWS:
		board.add_child(_header(Rules.ROW_NAMES[row]))
		for col: int in Rules.GRID_COLS:
			var panel: PanelContainer = PanelContainer.new()
			panel.custom_minimum_size = Vector2(190.0, 112.0)
			var label: Label = Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			panel.add_child(label)
			board.add_child(panel)
			cells[Vector2i(col, row)] = label


func _header(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	label.custom_minimum_size = Vector2(48.0, 24.0)
	return label


func _show(title: String, errors: Array[String]) -> void:
	team_label.text = title

	# 棋盤
	var placed: Dictionary = {}     # 格子 -> UnitInfo（同一格有兩隻只畫第一隻）
	for info: UnitInfo in units:
		if Rules.is_valid_cell(info.cell) and not placed.has(info.cell):
			placed[info.cell] = info
	for cell: Vector2i in cells:
		var label: Label = cells[cell]
		var info: UnitInfo = placed.get(cell)
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.set_corner_radius_all(6)
		style.set_border_width_all(2)
		style.set_content_margin_all(6.0)
		if info == null:
			style.bg_color = Color(1, 1, 1, 0.04)
			style.border_color = Color(1, 1, 1, 0.12)
			label.text = "%s\nVector2i(%d, %d)" % [Rules.cell_name(cell), cell.x, cell.y]
			label.add_theme_color_override("font_color", Color(1, 1, 1, 0.25))
		else:
			style.bg_color = info.color.darkened(0.6)
			style.border_color = info.color
			label.text = "%s%s\n%s　攻 %d　血 %d\n%d 點" % [_icon(info.school), info.name, info.role, info.attack, info.max_hp, info.cost]
			label.add_theme_color_override("font_color", Color.WHITE)
		(label.get_parent() as PanelContainer).add_theme_stylebox_override("panel", style)

	# 左邊的成員清單
	for child: Node in member_list.get_children():
		child.queue_free()
	var total: int = 0
	var schools: Array[int] = []
	schools.resize(Rules.SCHOOL_NAMES.size())
	for info: UnitInfo in units:
		total += info.cost
		schools[info.school] += 1
		member_list.add_child(_member_entry(info))
	var school_parts: Array[String] = []
	for school: int in range(1, schools.size()):
		if schools[school] > 0:
			var active: String = "（啟動）" if Rules.school_tier(schools[school]) > 0 else ""
			school_parts.append("%s%s %d/%d%s" % [_icon(school), Rules.SCHOOL_NAMES[school], schools[school],
					Rules.SCHOOL_TIERS[-1], active])
	if not school_parts.is_empty():
		team_label.text = "%s\n%s" % [title, "　".join(school_parts)]

	var over: bool = total > Rules.BUDGET or units.size() > Rules.MAX_UNITS
	budget_label.text = "預算 %d / %d　　角色 %d / %d" % [total, Rules.BUDGET, units.size(), Rules.MAX_UNITS]
	budget_label.add_theme_color_override("font_color", Color("#ff6b5e") if over else Color("#e8e8e8"))
	try_button.disabled = not passed
	try_button.tooltip_text = "" if passed else "隊伍還沒通過檢查"

	var lines: Array[String] = []
	for error: String in errors:
		lines.append("[color=#ff8a80]✗ %s[/color]" % error)
	if lines.is_empty():
		lines.append("[color=#6ee36e]✓ 隊伍通過檢查，可以試打了[/color]")
	status_label.text = "\n".join(lines)


func _member_entry(info: UnitInfo) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = info.color.darkened(0.65)
	style.border_color = info.color
	style.border_width_left = 6
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8.0)
	panel.add_theme_stylebox_override("panel", style)
	var label: Label = Label.new()
	label.text = "%s%s（%s）　%s\n攻 %d　血 %d　花費 %d　流派 %s　　%s" % [_icon(info.school), info.name, info.role,
			Rules.cell_name(info.cell), info.attack, info.max_hp, info.cost, Rules.SCHOOL_NAMES[info.school], info.path.get_file()]
	panel.add_child(label)
	return panel


## 流派圖示加一個空白；沒有流派是空字串
func _icon(school: int) -> String:
	return "" if school == 0 else Rules.SCHOOL_ICONS[school] + " "
