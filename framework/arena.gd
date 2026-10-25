extends Node2D
## 擂台：檢查隊伍、讀 team.gd 和 Boss，一回合一回合播放戰鬥。
## 上半部是 Boss 的棋盤（前排在下面），下半部是我方棋盤（前排在上面），兩邊的前排面對面。

const STEP_TIME: float = 0.9      # 每回合至少停這麼久
const ACTION_GAP: float = 0.16    # 同一回合裡，每隻角色行動之間的間隔
const BOARD_X: float = 320.0      # 棋盤中心的 x
const BOARD_TOP: float = 56.0
const CELL_W: float = 180.0
const ROW_H: float = 88.0
const MID_GAP: float = 24.0       # 兩個棋盤中間的空隙
const UNIT_SCALE: float = 0.62
const LUNGE: float = 26.0         # 攻擊時往目標衝多遠

@onready var units_root: Node2D = $Units
@onready var title_label: Label = $UI/Title
@onready var banner: Label = $UI/Banner
@onready var log_label: RichTextLabel = $UI/Log

var battle: Battle
var holders: Dictionary = {}      # Unit -> 包住它的 Node2D（框架移動 holder，學員的 on_frame 只動 Unit 自己）
var speed: float = 1.0
var paused: bool = false
var _timer: float = 0.0
var _wait: float = STEP_TIME
var _fx_delay: float = 0.0        # 這回合下一個畫面效果要延遲多久才播


func _ready() -> void:
	var boss_key: String = MatchSetup.boss_key
	if not Rules.BOSSES.has(boss_key):
		_show_errors(["Boss 要是 %s 其中一個，現在是 \"%s\"" % [", ".join(Rules.BOSSES.keys()), boss_key]])
		return
	var errors: Array[String] = Validator.check_team_folder(MatchSetup.team)
	if not errors.is_empty():
		_show_errors(errors)
		return

	var team: Team = Team.load_folder(MatchSetup.team)
	battle = Battle.new(team.members, [load(Rules.BOSSES[boss_key]) as Script])
	battle.logged.connect(_on_logged)
	battle.unit_added.connect(_add_holder)
	battle.unit_died.connect(_on_unit_died)
	battle.unit_damaged.connect(_on_unit_damaged)
	battle.unit_healed.connect(_on_unit_healed)
	battle.unit_acted.connect(_on_unit_acted)
	battle.finished.connect(_on_finished)
	for team_units: Array in battle.teams:
		for unit: Unit in team_units:
			_add_holder(unit)

	var boss_name: String = battle.teams[Battle.ENEMY][0].unit_name
	for unit: Unit in battle.teams[Battle.ENEMY]:
		if unit is Boss:
			boss_name = unit.unit_name
	title_label.text = "挑戰：%s　　%s：%s" % [boss_name, team.label(), Validator.describe_cost(team.members)]
	_fx_delay = 0.0
	battle.start()


func _process(delta: float) -> void:
	if battle == null or battle.result != "" or paused:
		return
	_timer += delta * speed
	if _timer >= _wait:
		_timer = 0.0
		_fx_delay = 0.0
		battle.step()
		_wait = maxf(STEP_TIME, _fx_delay + 0.4)


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_R:
			get_tree().reload_current_scene()
		KEY_ESCAPE:
			get_tree().change_scene_to_file(Rules.PREVIEW_SCENE)
		KEY_SPACE:
			paused = not paused
		KEY_1:
			speed = 1.0
		KEY_2:
			speed = 2.0
		KEY_3:
			speed = 4.0


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for team: int in [Battle.PLAYER, Battle.ENEMY]:
		var tint: Color = Color(Battle.TEAM_COLORS[team])
		for row: int in Rules.GRID_ROWS:
			for col: int in Rules.GRID_COLS:
				var center: Vector2 = cell_position(team, Vector2i(col, row))
				var rect: Rect2 = Rect2(center - Vector2(CELL_W - 10.0, ROW_H - 8.0) / 2.0, Vector2(CELL_W - 10.0, ROW_H - 8.0))
				draw_rect(rect, Color(tint, 0.06))
				draw_rect(rect, Color(tint, 0.18), false, 1.0)
			var y: float = cell_position(team, Vector2i(0, row)).y
			draw_string(font, Vector2(8.0, y + 5.0), Rules.ROW_NAMES[row], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.35))
	var mid_y: float = BOARD_TOP + ROW_H * Rules.GRID_ROWS + MID_GAP / 2.0
	draw_line(Vector2(40.0, mid_y), Vector2(BOARD_X * 2.0 - 10.0, mid_y), Color(1, 1, 1, 0.12), 2.0)


## 格子在畫面上的中心點
func cell_position(team: int, cell: Vector2i) -> Vector2:
	var x: float = BOARD_X + (cell.x - 1) * CELL_W
	var row_from_top: int = (Rules.GRID_ROWS - 1 - cell.y) if team == Battle.ENEMY else cell.y
	var top: float = BOARD_TOP if team == Battle.ENEMY else BOARD_TOP + ROW_H * Rules.GRID_ROWS + MID_GAP
	return Vector2(x, top + (row_from_top + 0.5) * ROW_H)


# ---------------------------------------------------------------- 畫面

func _add_holder(unit: Unit) -> void:
	var holder: Node2D = Node2D.new()
	holder.position = cell_position(unit._framework_team, unit.grid_position)
	holder.scale = Vector2.ONE * UNIT_SCALE
	holder.add_child(unit)
	units_root.add_child(holder)
	holders[unit] = holder


## 等 delay 秒（會跟著倍速變快）再呼叫 callback；綁在擂台上，重新開始時會一起取消
func _later(delay: float, callback: Callable) -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(maxf(0.001, delay / speed))
	tween.tween_callback(callback)


func _popup(unit: Unit, text: String, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.position = holders[unit].position + Vector2(-12.0, -unit.body_radius * UNIT_SCALE - 30.0)
	add_child(label)
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 34.0, 0.8 / speed)
	tween.tween_property(label, "modulate:a", 0.0, 0.8 / speed).set_delay(0.3 / speed)
	tween.chain().tween_callback(label.queue_free)


func _on_unit_acted(unit: Unit, target: Unit) -> void:
	_fx_delay += ACTION_GAP
	_later(_fx_delay, _play_lunge.bind(unit, target))


func _play_lunge(unit: Unit, target: Unit) -> void:
	var holder: Node2D = holders[unit]
	var home: Vector2 = cell_position(unit._framework_team, unit.grid_position)
	var to_target: Vector2 = holders[target].position - home
	var offset: Vector2 = to_target.normalized() * minf(LUNGE, to_target.length() * 0.5)
	var tween: Tween = create_tween()
	tween.tween_property(holder, "position", home + offset, 0.08 / speed).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "position", home, 0.14 / speed).set_ease(Tween.EASE_IN)


func _on_unit_damaged(unit: Unit, amount: int) -> void:
	_later(_fx_delay + 0.08, _play_hurt.bind(unit, amount))


func _play_hurt(unit: Unit, amount: int) -> void:
	_popup(unit, "-%d" % amount, Color("#ff6b5e"))
	var holder: Node2D = holders[unit]
	holder.modulate = Color(1.0, 0.3, 0.3)
	create_tween().tween_property(holder, "modulate", Color.WHITE, 0.3 / speed)


func _on_unit_healed(unit: Unit, amount: int) -> void:
	_later(_fx_delay + 0.08, _popup.bind(unit, "+%d" % amount, Color("#6ee36e")))


func _on_unit_died(unit: Unit) -> void:
	_later(_fx_delay + 0.3, _play_death.bind(unit))


func _play_death(unit: Unit) -> void:
	var holder: Node2D = holders[unit]
	var tween: Tween = create_tween()
	tween.tween_property(holder, "modulate:a", 0.0, 0.4 / speed)
	tween.tween_callback(holder.hide)


func _on_logged(text: String) -> void:
	log_label.append_text(text + "\n")


func _on_finished(result: String) -> void:
	banner.text = "勝利！" if result == "win" else "落敗…"
	banner.add_theme_color_override("font_color", Color("#ffd75e") if result == "win" else Color("#ff8a80"))
	_later(_fx_delay + 0.4, banner.show)


func _show_errors(errors: Array[String]) -> void:
	title_label.text = "隊伍沒有通過檢查，改好程式後按 Esc 回陣型預覽"
	banner.text = "無法上場"
	banner.add_theme_color_override("font_color", Color("#ff8a80"))
	banner.show()
	for error: String in errors:
		log_label.append_text("[color=#ff5252]✗ %s[/color]\n" % error)
