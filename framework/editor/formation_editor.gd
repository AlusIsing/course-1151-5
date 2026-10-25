class_name FormationEditor
extends Control
## 陣型編輯器：把 teams/<名字>/ 底下的角色拖到 3×3 棋盤上，存成 formation.json。
##
## 拖放用 Godot 的 _get_drag_data / _can_drop_data / _drop_data：
##   清單 → 格子：放上去（格子有人就換掉）
##   格子 → 格子：移過去（格子有人就交換）
##   格子 → 清單：移除
## 拖曳的資料是 {"from": "roster" 或 "cell", "path": 腳本路徑, "cell": 原本的格子}

const NO_CELL: Vector2i = Vector2i(-1, -1)

## 一隻角色的數值，讀腳本時算好，畫格子和算預算用
class UnitInfo:
	var name: String
	var role: String
	var max_hp: int
	var attack: int
	var cost: int
	var color: Color

@onready var team_select: OptionButton = %TeamSelect
@onready var boss_select: OptionButton = %BossSelect
@onready var budget_label: Label = %Budget
@onready var save_button: Button = %SaveButton
@onready var try_button: Button = %TryButton
@onready var reload_button: Button = %ReloadButton
@onready var roster_panel: RosterPanel = %Roster
@onready var roster_list: VBoxContainer = %RosterList
@onready var board: GridContainer = %Board
@onready var status_label: RichTextLabel = %Status

var team_names: Array[String] = []
var boss_keys: Array[String] = []
var formation: Formation = Formation.new()
var infos: Dictionary = {}          # 腳本路徑 -> UnitInfo（null 代表不是角色）
var cells: Dictionary = {}          # Vector2i -> BoardCell
var hover_cell: Vector2i = NO_CELL
var saved_units: String = ""        # 上次存檔的內容，用來判斷有沒有改過
var notice: String = ""             # 存檔成功之類的訊息


func _ready() -> void:
	roster_panel.editor = self
	_build_board()
	for key: String in Rules.BOSSES:
		boss_keys.append(key)
		boss_select.add_item("%s %s" % [key, _boss_name(key)])

	for dir_name: String in DirAccess.get_directories_at(Rules.TEAMS_DIR):
		if not dir_name.begins_with("."):
			team_names.append(dir_name)
	if not team_names.has(MatchSetup.team_name):
		MatchSetup.team_name = Rules.DEFAULT_TEAM if team_names.has(Rules.DEFAULT_TEAM) else ""
		if MatchSetup.team_name == "" and not team_names.is_empty():
			MatchSetup.team_name = team_names[0]
	for team_name: String in team_names:
		team_select.add_item(team_name)

	team_select.item_selected.connect(func(index: int) -> void:
		MatchSetup.formation = null
		_load_team(team_names[index]))
	boss_select.item_selected.connect(func(_index: int) -> void: _refresh())
	save_button.pressed.connect(_save)
	try_button.pressed.connect(_try)
	reload_button.pressed.connect(func() -> void:
		infos.clear()
		formation.boss_key = _selected_boss()
		_load_team(MatchSetup.team_name, formation))

	if team_names.is_empty():
		status_label.text = "[color=#ff8a80]%s 底下沒有隊伍資料夾[/color]" % Rules.TEAMS_DIR
		return
	team_select.select(team_names.find(MatchSetup.team_name))
	_load_team(MatchSetup.team_name, MatchSetup.formation)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		set_hover_cell(NO_CELL)


# ---------------------------------------------------------------- 讀取

## edits 是還沒存檔的陣型（試打回來、按重新讀取），null 就讀 formation.json
func _load_team(team_name: String, edits: Formation = null) -> void:
	MatchSetup.team_name = team_name
	var dir: String = Rules.team_dir(team_name)
	var on_disk: Formation = Formation.load_dir(dir)
	saved_units = _units_json(on_disk)
	formation = edits.copy() if edits != null else on_disk
	notice = ""

	var boss_key: String = formation.boss_key
	var boss_index: int = boss_keys.find(boss_key)
	boss_select.select(boss_index if boss_index >= 0 else maxi(0, boss_keys.find(Rules.DEFAULT_BOSS)))

	for child: Node in roster_list.get_children():
		child.queue_free()
	var count: int = 0
	for file_name: String in DirAccess.get_files_at(dir):
		if not file_name.ends_with(".gd"):
			continue
		var path: String = "%s/%s" % [dir, file_name]
		var info: UnitInfo = _info(path)
		if info == null:
			continue
		var text: String = "%s（%s）\n攻 %d　血 %d　花費 %d" % [info.name, info.role, info.attack, info.max_hp, info.cost]
		roster_list.add_child(RosterEntry.new(self, path, text, info.color))
		count += 1
	if count == 0:
		var hint: Label = Label.new()
		hint.text = "%s/ 裡還沒有角色。\n新增一個 extends Unit 的 .gd 檔，\n再按「重新讀取」就會出現在這裡。" % dir.trim_prefix("res://")
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		roster_list.add_child(hint)
	_refresh()


## 讀腳本的數值；不是角色（或是 Boss）就回傳 null
func _info(path: String) -> UnitInfo:
	if infos.has(path):
		return infos[path]
	var info: UnitInfo = null
	var script: Script = load(path) as Script if ResourceLoader.exists(path) else null
	if script != null and script.can_instantiate():
		var instance: Object = script.new()
		if instance is Unit and not instance is Boss:
			var unit: Unit = instance
			info = UnitInfo.new()
			info.name = unit.unit_name
			info.role = unit.get_role()
			info.max_hp = unit.max_hp
			info.attack = unit.attack
			info.cost = Rules.unit_cost(unit.max_hp, unit.attack)
			info.color = unit.color
		if instance is Node:
			(instance as Node).free()
	infos[path] = info
	return info


func _boss_name(key: String) -> String:
	var script: Script = load("%s/boss.gd" % Rules.BOSSES[key]) as Script
	if script == null:
		return ""
	var boss: Node = script.new()
	var boss_name: String = (boss as Unit).unit_name
	boss.free()
	return boss_name


func _units_json(f: Formation) -> String:
	var units: Array[String] = []
	for slot: Formation.Slot in f.sorted_slots():
		units.append("%s@%d,%d" % [slot.path, slot.cell.x, slot.cell.y])
	return ";".join(units)


# ---------------------------------------------------------------- 畫面

func _build_board() -> void:
	board.columns = Rules.GRID_COLS + 1
	board.add_child(Control.new())
	for col: int in Rules.GRID_COLS:
		board.add_child(_header(Rules.COL_NAMES[col]))
	for row: int in Rules.GRID_ROWS:
		board.add_child(_header(Rules.ROW_NAMES[row]))
		for col: int in Rules.GRID_COLS:
			var cell: Vector2i = Vector2i(col, row)
			var board_cell: BoardCell = BoardCell.new(self, cell)
			cells[cell] = board_cell
			board.add_child(board_cell)


func _header(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	label.custom_minimum_size = Vector2(48.0, 24.0)
	return label


func _refresh() -> void:
	for cell: Vector2i in cells:
		_paint_cell(cells[cell])

	var total: int = 0
	for slot: Formation.Slot in formation.slots:
		var info: UnitInfo = _info(slot.path)
		total += info.cost if info != null else 0
	var count: int = formation.slots.size()
	var over: bool = total > Rules.BUDGET or count > Rules.MAX_UNITS
	var dirty: bool = _units_json(formation) != saved_units
	budget_label.text = "預算 %d / %d　　角色 %d / %d%s" % [total, Rules.BUDGET, count, Rules.MAX_UNITS,
			"　（未存檔）" if dirty else ""]
	budget_label.add_theme_color_override("font_color", Color("#ff6b5e") if over else Color("#e8e8e8"))
	save_button.disabled = over
	save_button.tooltip_text = "超過預算或角色太多，不能存檔" if over else ""

	var lines: Array[String] = []
	if notice != "":
		lines.append("[color=#6ee36e]%s[/color]" % notice)
	if total > Rules.BUDGET:
		lines.append("[color=#ff6b5e]超過預算 %d 點，拿掉或換掉一些角色才能存檔[/color]" % (total - Rules.BUDGET))
	if count > 0:
		for error: String in Validator.check_formation(formation):
			if not error.begins_with("總花費"):
				lines.append("[color=#ffb74d]⚠ %s[/color]" % error)
	if lines.is_empty():
		lines.append("[color=#9e9e9e]把左邊的角色拖到棋盤上；拖回左邊就會移除。前排在最上面，面對敵人。[/color]")
	status_label.text = "\n".join(lines)


func _paint_cell(board_cell: BoardCell) -> void:
	var slot: Formation.Slot = formation.slot_at(board_cell.cell)
	var info: UnitInfo = _info(slot.path) if slot != null else null
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.set_content_margin_all(6.0)
	if slot == null:
		style.bg_color = Color(1, 1, 1, 0.04)
		style.border_color = Color(1, 1, 1, 0.12)
		board_cell.label.text = Rules.cell_name(board_cell.cell)
		board_cell.label.add_theme_color_override("font_color", Color(1, 1, 1, 0.25))
		board_cell.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		var color: Color = info.color if info != null else Color("#ff5252")
		style.bg_color = color.darkened(0.6)
		style.border_color = color
		board_cell.label.text = "%s\n%s　攻 %d　血 %d\n%d 點" % [info.name, info.role, info.attack, info.max_hp, info.cost] \
				if info != null else "讀不到\n%s" % slot.path.get_file()
		board_cell.label.add_theme_color_override("font_color", Color.WHITE)
		board_cell.mouse_default_cursor_shape = Control.CURSOR_DRAG
	if board_cell.cell == hover_cell:
		style.border_color = Color("#ffd75e")
		style.set_border_width_all(4)
	board_cell.add_theme_stylebox_override("panel", style)


func set_hover_cell(cell: Vector2i) -> void:
	if cell == hover_cell:
		return
	var old: Vector2i = hover_cell
	hover_cell = cell
	for c: Vector2i in [old, cell]:
		if cells.has(c):
			_paint_cell(cells[c])


func _preview(path: String) -> Control:
	var info: UnitInfo = _info(path)
	var label: Label = Label.new()
	label.text = info.name if info != null else path.get_file()
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.modulate = Color(1, 1, 1, 0.85)
	return label


# ---------------------------------------------------------------- 拖放

func drag_from_roster(path: String) -> Variant:
	set_drag_preview(_preview(path))
	return {"from": "roster", "path": path, "cell": NO_CELL}


func drag_from_cell(cell: Vector2i) -> Variant:
	var slot: Formation.Slot = formation.slot_at(cell)
	if slot == null:
		return null
	set_drag_preview(_preview(slot.path))
	return {"from": "cell", "path": slot.path, "cell": cell}


func can_drop_on_cell(cell: Vector2i, data: Variant) -> bool:
	if not data is Dictionary or not data.has("from"):
		return false
	if data["from"] == "cell":
		return data["cell"] != cell
	# 從清單拖：格子有人就是替換，不會多一隻
	return formation.slot_at(cell) != null or formation.slots.size() < Rules.MAX_UNITS


func drop_on_cell(cell: Vector2i, data: Variant) -> void:
	var target: Formation.Slot = formation.slot_at(cell)
	if data["from"] == "roster":
		if target != null:
			target.path = data["path"]
		else:
			formation.slots.append(Formation.Slot.new(data["path"], cell))
	else:
		var moving: Formation.Slot = formation.slot_at(data["cell"])
		if target != null:
			target.cell = moving.cell
		moving.cell = cell
	_changed()


func can_drop_on_roster(data: Variant) -> bool:
	return data is Dictionary and data.get("from") == "cell"


func drop_on_roster(data: Variant) -> void:
	formation.slots.erase(formation.slot_at(data["cell"]))
	_changed()


func _changed() -> void:
	notice = ""
	hover_cell = NO_CELL
	_refresh()


# ---------------------------------------------------------------- 按鈕

func _selected_boss() -> String:
	return boss_keys[maxi(0, boss_select.selected)]


func _save() -> void:
	if save_button.disabled:
		return
	formation.boss_key = _selected_boss()
	var dir: String = Rules.team_dir(MatchSetup.team_name)
	var error: Error = formation.save_dir(dir)
	if error != OK:
		notice = ""
		status_label.text = "[color=#ff6b5e]存檔失敗：%s[/color]" % error_string(error)
		return
	saved_units = _units_json(formation)
	MatchSetup.formation = null
	notice = "已存到 %s/%s" % [dir.trim_prefix("res://"), Formation.FILE_NAME]
	_refresh()


func _try() -> void:
	formation.boss_key = _selected_boss()
	MatchSetup.formation = formation.copy()
	MatchSetup.boss_key = _selected_boss()
	get_tree().change_scene_to_file(Rules.ARENA_SCENE)
