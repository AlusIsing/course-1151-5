class_name Unit
extends Node2D
## 所有角色的父類別。
##
## 學員的角色要 `extends Unit`，在 _init() 設定屬性，再覆寫想要的事件方法：
##
##     extends Unit
##
##     func _init() -> void:
##         unit_name = "史萊姆"
##         max_hp = 12
##         attack = 3
##         grid_position = Vector2i(1, 0)   # 站前排中間
##
##     func on_hurt(amount: int, source: Unit) -> void:
##         heal(self, 1)

# --- 框架內部（學員不要碰，validator 會擋）---
var _framework_writing := false
var _framework_locked := false
var _framework_dead := false
var _framework_battle: Battle = null
var _framework_team := 0

# --- 屬性（學員在子類別的 _init() 設定，validator 會檢查預算）---
var unit_name: String = "Unit"
var max_hp: int = 10:
	set(value):
		if _framework_locked and not _framework_writing:
			_framework_reject("戰鬥開始後不能改 max_hp！")
			return
		max_hp = value
		queue_redraw()
var attack: int = 2:
	set(value):
		if _framework_locked and not _framework_writing:
			_framework_reject("戰鬥開始後不能直接改 attack！請用 buff_attack()")
			return
		attack = value
		queue_redraw()
## 站在棋盤哪一格：x 是行（0 左、1 中、2 右），y 是排（0 前排、1 中排、2 後排）
var grid_position: Vector2i = Vector2i(-1, -1):
	set(value):
		if _framework_locked and not _framework_writing:
			_framework_reject("戰鬥開始後不能移動！")
			return
		grid_position = value

# --- 外觀（不影響戰鬥，隨便改）---
var color: Color = Color("#6cb4ee")
var body_radius: float = 34.0
var status_text: String = "":
	set(value):
		status_text = value
		queue_redraw()

# --- 戰鬥狀態（唯讀，只有框架能改）---
var hp: int:
	set(value):
		if not _framework_writing:
			_framework_reject("不能直接改 hp！請用 deal_damage() 或 heal()")
			return
		hp = value
		queue_redraw()


# --- 事件方法（學員覆寫這些）---
func on_battle_start() -> void: pass
func on_attack(target: Unit) -> void: pass
func on_hurt(amount: int, source: Unit) -> void: pass
func on_death() -> void: pass
func on_ally_death(ally: Unit) -> void: pass

# --- 視覺效果（每幀呼叫，不能呼叫戰鬥 API）---
func on_frame(delta: float) -> void: pass


# --- 戰鬥 API（技能只能透過這些生效，裡面有數值上限）---

## 對 target 造成傷害（每次 1–5）
func deal_damage(target: Unit, amount: int) -> void:
	if _framework_has_battle("deal_damage"):
		_framework_battle.api_deal_damage(self, target, amount)

## 幫 target 回血（每次 1–5，不會超過 max_hp）
func heal(target: Unit, amount: int) -> void:
	if _framework_has_battle("heal"):
		_framework_battle.api_heal(self, target, amount)

## 幫 target 加攻擊（每次 1–3，最多加到 15）
func buff_attack(target: Unit, amount: int) -> void:
	if _framework_has_battle("buff_attack"):
		_framework_battle.api_buff_attack(self, target, amount)

## 召喚一隻沒有技能的小兵到自己的位置（只能在 on_death 用，總共 hp + 2×attack ≤ 10）
func summon_token(token_hp: int, token_attack: int) -> void:
	if _framework_has_battle("summon_token"):
		_framework_battle.api_summon_token(self, token_hp, token_attack)

## 在戰鬥紀錄說一句話
func say(text: String) -> void:
	if _framework_has_battle("say"):
		_framework_battle.api_say(self, text)

## 還活著的隊友（包含自己），最前排在 [0]
func get_allies() -> Array[Unit]:
	if _framework_battle == null:
		return []
	return _framework_battle.get_alive(_framework_team)

## 還活著的敵人，最前排在 [0]
func get_enemies() -> Array[Unit]:
	if _framework_battle == null:
		return []
	return _framework_battle.get_alive(1 - _framework_team)

## 自己在 get_allies() 裡排第幾個（照行動順序：前排 → 後排、左 → 右）
func get_slot() -> int:
	return get_allies().find(self)

## 自己站的格子：x 是行（0 左、1 中、2 右），y 是排（0 前排、1 中排、2 後排）
func get_grid_position() -> Vector2i:
	return grid_position

## 上下左右相鄰、還活著的隊友（不含自己）
func get_adjacent_allies() -> Array[Unit]:
	if _framework_battle == null:
		return []
	return _framework_battle.adjacent_allies(self)

## 某一排還活著的角色，由左到右。enemy = true 查敵方，false 查我方
func get_units_in_row(row: int, enemy: bool) -> Array[Unit]:
	if _framework_battle == null:
		return []
	return _framework_battle.units_in_row(_framework_team if not enemy else 1 - _framework_team, row)

## 某一行還活著的角色，由前排到後排。enemy = true 查敵方，false 查我方
func get_units_in_column(col: int, enemy: bool) -> Array[Unit]:
	if _framework_battle == null:
		return []
	return _framework_battle.units_in_column(_framework_team if not enemy else 1 - _framework_team, col)

## 職業名稱（戰士、坦克、射手、法師、補師、刺客），直接 extends Unit 的算戰士
func get_role() -> String:
	return "戰士"

## 現在是第幾回合（on_battle_start 時是 0）
func get_round() -> int:
	return _framework_battle.round_number if _framework_battle else 0

func is_alive() -> bool:
	return not _framework_dead and hp > 0

## 固定種子的隨機整數（a ≤ 結果 ≤ b）。不要用 randi()，結果會不固定
func random_int(a: int, b: int) -> int:
	return _framework_battle.rng.randi_range(a, b) if _framework_battle else a

## 固定種子地從陣列隨機挑一個
func random_pick(items: Array) -> Variant:
	if items.is_empty():
		return null
	return items[random_int(0, items.size() - 1)]


# --- 以下是框架內部 ---

func _process(delta: float) -> void:
	if not _framework_dead:
		on_frame(delta)


func _framework_has_battle(api: String) -> bool:
	if _framework_battle == null:
		push_error("%s() 只能在戰鬥中使用" % api)
		return false
	return true


func _framework_reject(message: String) -> void:
	push_error("%s：%s" % [unit_name, message])
	if _framework_battle:
		_framework_battle.report_violation(self, message)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var r := body_radius
	var w := maxf(140.0, r * 2.0 + 12.0)

	# 身體 + 眼睛
	draw_circle(Vector2.ZERO, r, color)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, color.darkened(0.45), 3.0)
	var eye_x := r * 0.32
	var eye_y := -r * 0.15
	var eye_r := maxf(2.5, r * 0.11)
	draw_circle(Vector2(-eye_x, eye_y), eye_r, Color(0.1, 0.1, 0.12))
	draw_circle(Vector2(eye_x, eye_y), eye_r, Color(0.1, 0.1, 0.12))

	# 名字、狀態
	draw_string(font, Vector2(-w / 2.0, -r - 10.0), unit_name,
			HORIZONTAL_ALIGNMENT_CENTER, w, 16)
	if status_text != "":
		draw_string(font, Vector2(-w / 2.0, -r - 32.0), status_text,
				HORIZONTAL_ALIGNMENT_CENTER, w, 15, Color("#ffd75e"))

	# 血條、數值
	var bar_y := r + 10.0
	var ratio := clampf(float(hp) / maxf(1.0, max_hp), 0.0, 1.0)
	var bar_color := Color("#5fd35f") if ratio > 0.3 else Color("#ff6b5e")
	draw_rect(Rect2(-w / 2.0, bar_y, w, 8.0), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(-w / 2.0, bar_y, w * ratio, 8.0), bar_color)
	draw_string(font, Vector2(-w / 2.0, bar_y + 26.0),
			"攻 %d　血 %d/%d" % [attack, hp, max_hp],
			HORIZONTAL_ALIGNMENT_CENTER, w, 14)
