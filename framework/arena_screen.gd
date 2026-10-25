extends Node2D
## 擂台畫面：試打 Boss 時播一場；擂台賽時讀 matches.gd，最多 4 場同時播放（2×2）。
## 點其中一場可以放大成全畫面，Esc 縮回來；全部顯示時按 Esc 回陣型預覽。

const ArenaScene: PackedScene = preload("res://framework/arena.tscn")
const SCREEN: Vector2 = Vector2(1152.0, 648.0)
const MAX_MATCHES: int = 4

var arenas: Array[Node2D] = []
var zoomed: int = -1              # 放大中的那場；-1 代表全部顯示
var speed: float = 1.0
var paused: bool = false


func _ready() -> void:
	if MatchSetup.mode == "boss":
		_add_arena().setup_boss(MatchSetup.team, MatchSetup.boss_key)
	else:
		var matches: Array = (load(Rules.MATCHES_PATH) as Script).get_script_constant_map().get("MATCHES", [])
		var problem: String = _check_matches(matches)
		if problem != "":
			var arena: Node2D = _add_arena()
			arena.show_errors([problem])
			arena.title_label.text = "擂台賽設定有誤，請修改 %s" % Rules.MATCHES_PATH.trim_prefix("res://")
		else:
			for pair: Array in matches:
				_add_arena().setup_versus(pair[0], pair[1])
	_layout()


func _check_matches(matches: Array) -> String:
	if matches.is_empty():
		return "MATCHES 是空的，請填入要對戰的 GitHub 帳號，例如 [\"帳號A\", \"帳號B\"]"
	if matches.size() > MAX_MATCHES:
		return "MATCHES 最多 %d 組，現在有 %d 組" % [MAX_MATCHES, matches.size()]
	for pair: Variant in matches:
		if not pair is Array or pair.size() != 2 or not pair[0] is String or not pair[1] is String:
			return "MATCHES 每一組要寫成 [\"帳號A\", \"帳號B\"]，這組不對：%s" % str(pair)
	return ""


func _add_arena() -> Node2D:
	var arena: Node2D = ArenaScene.instantiate()
	add_child(arena)
	arenas.append(arena)
	return arena


## 一場就全畫面；多場排成 2×2（兩場時排在中間一列）
func _layout() -> void:
	var grid: bool = arenas.size() > 1 and zoomed < 0
	for i: int in arenas.size():
		var arena: Node2D = arenas[i]
		arena.visible = grid or i == zoomed or arenas.size() == 1
		arena.set_compact(grid)
		if grid:
			arena.scale = Vector2.ONE * 0.5
			arena.position = _cell_origin(i)
		else:
			arena.scale = Vector2.ONE
			arena.position = Vector2.ZERO
	queue_redraw()


func _cell_origin(index: int) -> Vector2:
	var half: Vector2 = SCREEN / 2.0
	if arenas.size() == 2:
		return Vector2(index * half.x, half.y / 2.0)
	if arenas.size() == 3 and index == 2:
		return Vector2(half.x / 2.0, half.y)
	return Vector2((index % 2) * half.x, (index / 2) * half.y)


func _draw() -> void:
	if arenas.size() > 1 and zoomed < 0:
		var line: Color = Color(1, 1, 1, 0.35)
		for i: int in arenas.size():
			draw_rect(Rect2(_cell_origin(i), SCREEN / 2.0), line, false, 2.0)


func _unhandled_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT \
			and arenas.size() > 1 and zoomed < 0:
		var mouse: Vector2 = get_global_mouse_position()
		for i: int in arenas.size():
			if Rect2(_cell_origin(i), SCREEN / 2.0).has_point(mouse):
				zoomed = i
				_layout()
				return

	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_R:
			get_tree().reload_current_scene()
		KEY_ESCAPE:
			if zoomed >= 0:
				zoomed = -1
				_layout()
			else:
				get_tree().change_scene_to_file(Rules.PREVIEW_SCENE)
		KEY_SPACE:
			paused = not paused
		KEY_1:
			speed = 1.0
		KEY_2:
			speed = 2.0
		KEY_3:
			speed = 4.0
	for arena: Node2D in arenas:
		arena.paused = paused
		arena.speed = speed
