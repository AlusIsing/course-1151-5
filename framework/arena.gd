extends Node2D
## 擂台：讀 my_team/team.gd、檢查隊伍、一回合一回合播放戰鬥。

const STEP_TIME := 0.9
const CENTER_X := 576.0
const GROUND_Y := 250.0
const SLOT_GAP := 112.0

@onready var units_root: Node2D = $Units
@onready var title_label: Label = $UI/Title
@onready var banner: Label = $UI/Banner
@onready var log_label: RichTextLabel = $UI/Log

var battle: Battle
var holders := {}      # Unit -> 包住它的 Node2D（框架移動 holder，學員的 on_frame 只動 Unit 自己）
var speed := 1.0
var paused := false
var _timer := 0.0


func _ready() -> void:
	var team := (load(Rules.TEAM_PATH) as Script).get_script_constant_map()
	var members: Array = team.get("MEMBERS", [])
	var boss_key: String = team.get("BOSS", "dummy")

	if not Rules.BOSSES.has(boss_key):
		_show_errors(["BOSS 要是 %s 其中一個，現在是 \"%s\"" % [", ".join(Rules.BOSSES.keys()), boss_key]])
		return
	var errors := Validator.check_team(members)
	if not errors.is_empty():
		_show_errors(errors)
		return

	battle = Battle.new(members, load(Rules.BOSSES[boss_key]))
	battle.logged.connect(_on_logged)
	battle.unit_added.connect(_add_holder)
	battle.unit_died.connect(_on_unit_died)
	battle.unit_damaged.connect(_on_unit_damaged)
	battle.unit_healed.connect(_on_unit_healed)
	battle.finished.connect(_on_finished)
	for team_units in battle.teams:
		for unit in team_units:
			_add_holder(unit)
	_layout(false)

	var boss: Unit = battle.teams[Battle.ENEMY][0]
	title_label.text = "挑戰：%s　　隊伍：%s" % [boss.unit_name, Validator.describe_cost(members)]
	battle.start()
	_layout(true)


func _process(delta: float) -> void:
	if battle == null or battle.result != "" or paused:
		return
	_timer += delta * speed
	if _timer >= STEP_TIME:
		_timer = 0.0
		battle.step()
		_layout(true)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_R:
			get_tree().reload_current_scene()
		KEY_SPACE:
			paused = not paused
		KEY_1:
			speed = 1.0
		KEY_2:
			speed = 2.0
		KEY_3:
			speed = 4.0


func _draw() -> void:
	draw_rect(Rect2(0, GROUND_Y + 60.0, 1152.0, 6.0), Color(1, 1, 1, 0.08))
	draw_line(Vector2(CENTER_X, 90.0), Vector2(CENTER_X, GROUND_Y + 60.0), Color(1, 1, 1, 0.06), 2.0)


# ---------------------------------------------------------------- 畫面

func _add_holder(unit: Unit) -> void:
	var holder := Node2D.new()
	holder.position = _slot_position(unit._framework_team, battle.teams[unit._framework_team].find(unit))
	holder.add_child(unit)
	units_root.add_child(holder)
	holders[unit] = holder


func _slot_position(team: int, index: int) -> Vector2:
	if team == Battle.PLAYER:
		return Vector2(CENTER_X - 70.0 - index * SLOT_GAP, GROUND_Y)
	return Vector2(CENTER_X + 100.0 + index * SLOT_GAP, GROUND_Y)


func _layout(animate: bool) -> void:
	for team in [Battle.PLAYER, Battle.ENEMY]:
		var alive := battle.get_alive(team)
		for i in alive.size():
			var holder: Node2D = holders[alive[i]]
			var target := _slot_position(team, i)
			if animate:
				create_tween().tween_property(holder, "position", target, 0.3)
			else:
				holder.position = target


func _popup(unit: Unit, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.position = holders[unit].position + Vector2(-12.0, -unit.body_radius - 40.0)
	add_child(label)
	var tween := create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


func _on_unit_damaged(unit: Unit, amount: int) -> void:
	_popup(unit, "-%d" % amount, Color("#ff6b5e"))
	var holder: Node2D = holders[unit]
	holder.modulate = Color(1.0, 0.45, 0.45)
	create_tween().tween_property(holder, "modulate", Color.WHITE, 0.3)


func _on_unit_healed(unit: Unit, amount: int) -> void:
	_popup(unit, "+%d" % amount, Color("#6ee36e"))


func _on_unit_died(unit: Unit) -> void:
	var holder: Node2D = holders[unit]
	var tween := create_tween()
	tween.tween_property(holder, "modulate:a", 0.0, 0.4)
	tween.tween_callback(holder.hide)


func _on_logged(text: String) -> void:
	log_label.append_text(text + "\n")


func _on_finished(result: String) -> void:
	banner.text = "勝利！" if result == "win" else "落敗…"
	banner.add_theme_color_override("font_color", Color("#ffd75e") if result == "win" else Color("#ff8a80"))
	banner.show()


func _show_errors(errors: Array) -> void:
	title_label.text = "隊伍沒有通過檢查，請修正後按 F5 重新執行"
	banner.text = "無法上場"
	banner.add_theme_color_override("font_color", Color("#ff8a80"))
	banner.show()
	for error in errors:
		log_label.append_text("[color=#ff5252]✗ %s[/color]\n" % error)
