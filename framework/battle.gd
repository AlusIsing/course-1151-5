class_name Battle
extends RefCounted
## 戰鬥流程。純邏輯、不碰畫面，擂台和無畫面模擬共用。
##
## 雙方各有 3×3 棋盤（前排、中排、後排），角色站好就不會移動。
##
## 一回合的順序：
##   1. Boss 的 on_round_start
##   2. 照行動順序，每隻角色輪流行動：選目標 → 扣血 → 自己的 on_attack → 受傷者的 on_hurt
##   3. 結算死亡：on_death → 隊友的 on_ally_death → 從場上移除（召喚的分身站到原本的格子）
##   4. 一方全滅就結束；超過 MAX_ROUNDS 回合算挑戰者輸
##
## 行動順序固定：玩家隊伍先、Boss 隊伍後；同一隊由前排到後排、每排由左到右。
## 輪到的時候血量已經歸零的角色不會行動。
##
## 職業的攻擊目標（「最前排」指還有活著角色的最前面一排）：
##   戰士、坦克：敵方最前排，優先同一行，沒有就打最近的一行（一樣近打左邊）
##   刺客：敵方最後排，規則同上
##   射手：任何一格，由 Archer.choose_target() 決定（預設血最少）
##   法師：敵方同一行的所有角色；同一行沒人就打最近的一行
##   補師：不攻擊，幫相鄰有受傷的隊友回 attack 點血
##   坦克另外會替相鄰的隊友分擔 TANK_SHARE_PERCENT% 的傷害
##
## 規則細節：
##   - 血量歸零的角色只會再觸發 on_death，其他事件都不會觸發
##   - 技能造成的傷害會立刻觸發對方的 on_hurt，連鎖最多 MAX_EVENT_DEPTH 層

signal logged(text: String)
signal unit_added(unit: Unit)
signal unit_died(unit: Unit)
signal unit_damaged(unit: Unit, amount: int)
signal unit_healed(unit: Unit, amount: int)
signal unit_acted(unit: Unit, target: Unit)   # 普攻或治療，畫面拿來做「往目標衝一下」
signal finished(result: String)

const PLAYER := 0
const ENEMY := 1
const TEAM_COLORS := ["#7cc4ff", "#ff8a80"]

var teams: Array = [[], []]   # 兩隊還在場上的角色（Array of Unit），照行動順序排
var roster: Array[Unit] = []  # 這場戰鬥出現過的所有角色（包含陣亡的）
var round_number := 0
var result := ""              # "" 進行中 / "win" / "lose"
var result_reason := ""
var rng := RandomNumberGenerator.new()

# 目前正在執行事件的角色；戰鬥 API 只接受它呼叫
var _actor: Unit = null
var _event := ""
var _calls_left := 0
var _depth := 0
var _tokens := {}         # 死亡的角色 -> 牠召喚的 token 陣列
var _token_budget := {}   # 死亡的角色 -> 剩下的 token 預算


## player、enemy 是兩隊的陣型；腳本要先通過 Validator 檢查
func _init(player: Formation, enemy: Formation) -> void:
	rng.seed = Rules.SEED
	seed(Rules.SEED)
	for pair: Array in [[player, PLAYER], [enemy, ENEMY]]:
		var formation: Formation = pair[0]
		var slots: Array[Formation.Slot] = formation.sorted_slots()
		var scripts: Array[Script] = formation.load_scripts()
		for i: int in slots.size():
			_add_unit(scripts[i].new(), pair[1], slots[i].cell)


# ---------------------------------------------------------------- 流程

func start() -> void:
	_log("[b]=== 戰鬥開始（種子 %d）===[/b]" % Rules.SEED)
	for unit: Unit in _all_alive():
		_fire(unit, "on_battle_start", [])
	_resolve_deaths()
	_check_end()


func step() -> void:
	if result != "":
		return
	round_number += 1
	_log("[b]— 第 %d 回合 —[/b]" % round_number)

	for unit: Unit in _all_alive():
		if unit is Boss:
			_fire(unit, "on_round_start", [round_number])
	_resolve_deaths()
	if _check_end():
		return

	for unit: Unit in _all_alive():
		if unit.is_alive():
			_act(unit)

	_resolve_deaths()
	_check_end()


func _act(unit: Unit) -> void:
	var boss: Boss = unit as Boss
	if boss and boss.skip_attack:
		return
	if unit is Healer:
		_heal_neighbors(unit)
		return

	var targets: Array[Unit] = _pick_targets(unit)
	var amount: int = unit.attack
	if boss and boss.pierce:
		targets = get_alive(1 - unit._framework_team)
		amount = boss.pierce_damage
	if targets.is_empty() or amount <= 0:
		return

	unit_acted.emit(unit, targets[0])
	var hurt: Array = []      # [受傷者, 實際傷害]
	for target: Unit in targets:
		hurt.append_array(_apply_damage(target, amount, unit, "攻擊"))
	if unit.is_alive():
		_fire(unit, "on_attack", [targets[0]])
	for entry: Array in hurt:
		if entry[0].is_alive():
			_fire(entry[0], "on_hurt", [entry[1], unit])


func _heal_neighbors(healer: Unit) -> void:
	if healer.attack <= 0:
		return
	var first := true
	for ally: Unit in adjacent_allies(healer):
		var amount: int = mini(healer.attack, ally.max_hp - ally.hp)
		if amount <= 0:
			continue
		if first:
			unit_acted.emit(healer, ally)
			first = false
		_write(ally, "hp", ally.hp + amount)
		_log("%s 治療 %s，回了 %d 血（%d/%d）" % [_n(healer), _n(ally), amount, ally.hp, ally.max_hp])
		unit_healed.emit(ally, amount)


## 照職業挑普攻的目標（法師會回傳整行）
func _pick_targets(attacker: Unit) -> Array[Unit]:
	var enemy_team: int = 1 - attacker._framework_team
	var enemies: Array[Unit] = get_alive(enemy_team)
	if enemies.is_empty():
		return []
	var col: int = attacker._framework_cell.x

	if attacker is Mage:
		return units_in_column(enemy_team, _nearest_column(enemies, col))

	if attacker is Archer:
		var picked: Unit = (attacker as Archer).choose_target(enemies.duplicate())
		if picked == null or not enemies.has(picked):
			report_violation(attacker, "choose_target() 要回傳一隻還活著的敵人，這次改打 %s" % _n(enemies[0]))
			picked = enemies[0]
		return [picked]

	# 近戰打最前排、刺客打最後排；get_alive 照前排到後排排好
	var row: int = enemies[-1]._framework_cell.y if attacker is Assassin else enemies[0]._framework_cell.y
	var in_row: Array[Unit] = units_in_row(enemy_team, row)
	return [in_row[_nearest_index(in_row, col)]]


## units 裡離 col 最近的那隻的索引；一樣近取前面的（units 由左到右排，所以是左邊）
func _nearest_index(units: Array[Unit], col: int) -> int:
	var best: int = 0
	for i: int in units.size():
		if absi(units[i]._framework_cell.x - col) < absi(units[best]._framework_cell.x - col):
			best = i
	return best


func _nearest_column(units: Array[Unit], col: int) -> int:
	var best: int = -1
	for unit: Unit in units:
		var c: int = unit._framework_cell.x
		if best < 0 or absi(c - col) < absi(best - col) or (absi(c - col) == absi(best - col) and c < best):
			best = c
	return best


func _resolve_deaths() -> void:
	# on_death 裡的技能可能再打死別人，所以重複結算到沒人死為止
	for _i: int in 20:
		var dying: Array[Unit] = []
		for unit: Unit in _all_units():
			if not unit._framework_dead and unit.hp <= 0:
				dying.append(unit)
		if dying.is_empty():
			return
		for unit: Unit in dying:
			unit._framework_dead = true
			_tokens[unit] = []
			_token_budget[unit] = Rules.TOKEN_BUDGET
		for unit: Unit in dying:
			_log("%s 倒下了" % _n(unit))
			_fire(unit, "on_death", [])
			for ally: Unit in get_alive(unit._framework_team):
				_fire(ally, "on_ally_death", [unit])
		for unit: Unit in dying:
			teams[unit._framework_team].erase(unit)
			unit_died.emit(unit)
			for token: Unit in _tokens[unit]:
				var cell: Vector2i = _free_cell_near(unit._framework_team, unit._framework_cell)
				if cell.x < 0:
					token.free()
					continue
				_add_unit(token, unit._framework_team, cell)
				unit_added.emit(token)
			_tokens.erase(unit)
			_token_budget.erase(unit)


## 離 origin 最近的空格（先看自己那格，再看上下左右，最後照行動順序找）
func _free_cell_near(team: int, origin: Vector2i) -> Vector2i:
	var candidates: Array[Vector2i] = [origin]
	for offset: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		candidates.append(origin + offset)
	for row: int in Rules.GRID_ROWS:
		for col: int in Rules.GRID_COLS:
			candidates.append(Vector2i(col, row))
	for cell: Vector2i in candidates:
		if Rules.is_valid_cell(cell) and _unit_at(team, cell) == null:
			return cell
	return Vector2i(-1, -1)


func _check_end() -> bool:
	var players := get_alive(PLAYER).size()
	var enemies := get_alive(ENEMY).size()
	if players == 0 and enemies == 0:
		_finish("lose", "同歸於盡，算挑戰者輸")
	elif enemies == 0:
		_finish("win", "擊敗了 Boss！")
	elif players == 0:
		_finish("lose", "全隊陣亡")
	elif round_number >= Rules.MAX_ROUNDS:
		_finish("lose", "超過 %d 回合還沒打倒 Boss" % Rules.MAX_ROUNDS)
	return result != ""


func _finish(new_result: String, reason: String) -> void:
	result = new_result
	result_reason = reason
	var title := "勝利" if result == "win" else "落敗"
	_log("[b]=== %s：%s（第 %d 回合）===[/b]" % [title, reason, round_number])
	finished.emit(result)


# ---------------------------------------------------------------- 事件

func _fire(unit: Unit, method: String, args: Array) -> void:
	if _depth >= Rules.MAX_EVENT_DEPTH:
		_log("[color=gray]（連鎖太深，%s 的 %s 被略過）[/color]" % [_n(unit), method])
		return
	var saved := [_actor, _event, _calls_left]
	_actor = unit
	_event = method
	_calls_left = Rules.CALLS_PER_EVENT
	_depth += 1
	unit.callv(method, args)
	_depth -= 1
	_actor = saved[0]
	_event = saved[1]
	_calls_left = saved[2]


## 扣血；相鄰有坦克的話坦克分擔一部分。回傳 [[受傷者, 實際傷害], ...]
func _apply_damage(target: Unit, amount: int, source: Unit, verb: String) -> Array:
	if not target.is_alive() or amount <= 0:
		return []
	var boss := target as Boss
	if boss:
		amount *= boss.damage_taken_multiplier
	var tank: Unit = _guarding_tank(target)
	var shared: int = amount * Rules.TANK_SHARE_PERCENT / 100 if tank else 0
	var taken: int = amount - shared

	var hurt: Array = []
	_write(target, "hp", maxi(0, target.hp - taken))
	_log("%s %s %s，造成 %d 傷害（剩 %d）" % [_n(source), verb, _n(target), taken, target.hp])
	unit_damaged.emit(target, taken)
	hurt.append([target, taken])
	if shared > 0:
		_write(tank, "hp", maxi(0, tank.hp - shared))
		_log("%s 替 %s 擋下 %d 傷害（剩 %d）" % [_n(tank), _n(target), shared, tank.hp])
		unit_damaged.emit(tank, shared)
		hurt.append([tank, shared])
	return hurt


## 會替 unit 分擔傷害的坦克：相鄰、還活著、行動順序最前面的那隻
func _guarding_tank(unit: Unit) -> Unit:
	for ally: Unit in adjacent_allies(unit):
		if ally is Tank:
			return ally
	return null


# ---------------------------------------------------------------- 戰鬥 API

func api_deal_damage(caller: Unit, target: Unit, amount: int) -> void:
	if not _api_begin(caller, "deal_damage") or not _check_target(caller, target, "deal_damage"):
		return
	amount = _cap(caller, "deal_damage", amount, 1, Rules.DAMAGE_CAP)
	for entry: Array in _apply_damage(target, amount, caller, "用技能打"):
		if entry[0].is_alive():
			_fire(entry[0], "on_hurt", [entry[1], caller])


func api_heal(caller: Unit, target: Unit, amount: int) -> void:
	if not _api_begin(caller, "heal") or not _check_target(caller, target, "heal"):
		return
	amount = _cap(caller, "heal", amount, 1, Rules.HEAL_CAP)
	amount = mini(amount, target.max_hp - target.hp)
	if amount <= 0:
		_log("%s 想幫 %s 回血，但牠已經滿血了" % [_n(caller), _n(target)])
		return
	_write(target, "hp", target.hp + amount)
	_log("%s 幫 %s 回了 %d 血（%d/%d）" % [_n(caller), _n(target), amount, target.hp, target.max_hp])
	unit_healed.emit(target, amount)


func api_buff_attack(caller: Unit, target: Unit, amount: int) -> void:
	if not _api_begin(caller, "buff_attack") or not _check_target(caller, target, "buff_attack"):
		return
	amount = _cap(caller, "buff_attack", amount, 1, Rules.BUFF_CAP)
	if not caller is Boss:
		amount = mini(amount, Rules.ATTACK_LIMIT - target.attack)
	if amount <= 0:
		_log("%s 想幫 %s 加攻擊，但已經到上限 %d 了" % [_n(caller), _n(target), Rules.ATTACK_LIMIT])
		return
	_write(target, "attack", target.attack + amount)
	_log("%s 幫 %s 加了 %d 攻擊（變成 %d）" % [_n(caller), _n(target), amount, target.attack])


func api_summon_token(caller: Unit, token_hp: int, token_attack: int) -> void:
	if not _api_begin(caller, "summon_token"):
		return
	if _event != "on_death":
		report_violation(caller, "summon_token() 只能在 on_death 裡用")
		return
	token_hp = maxi(1, token_hp)
	token_attack = maxi(0, token_attack)
	var cost := Rules.unit_cost(token_hp, token_attack)
	if cost > _token_budget[caller]:
		report_violation(caller, "召喚的 token 太貴（hp %d + 2×attack %d = %d，剩下的額度只有 %d）"
				% [token_hp, token_attack, cost, _token_budget[caller]])
		return
	var alive: int = get_alive(caller._framework_team).size() + _tokens[caller].size()
	if alive >= Rules.MAX_UNITS:
		_log("%s 想召喚，但隊伍已經滿 %d 隻了" % [_n(caller), Rules.MAX_UNITS])
		return
	_token_budget[caller] -= cost
	var token := Unit.new()
	token.unit_name = caller.unit_name + "分身"
	token.max_hp = token_hp
	token.attack = token_attack
	token.color = caller.color.lightened(0.35)
	token.body_radius = 24.0
	_tokens[caller].append(token)
	_log("%s 召喚了 %s（攻 %d、血 %d）" % [_n(caller), token.unit_name, token_attack, token_hp])


func api_say(caller: Unit, text: String) -> void:
	if _actor != caller:
		report_violation(caller, "say() 只能在戰鬥事件裡用（on_frame 不行）")
		return
	_log("%s：「%s」" % [_n(caller), text])


func report_violation(unit: Unit, message: String) -> void:
	_log("[color=#ff5252]⚠ %s：%s[/color]" % [_n(unit), message])


func _api_begin(caller: Unit, api: String) -> bool:
	if _actor != caller:
		report_violation(caller, "%s() 只能在自己的戰鬥事件裡用（on_frame、choose_target 不行）" % api)
		return false
	if caller is Boss:
		return true
	if _calls_left <= 0:
		report_violation(caller, "每個事件最多呼叫 %d 次戰鬥 API，這次 %s() 被略過" % [Rules.CALLS_PER_EVENT, api])
		return false
	_calls_left -= 1
	return true


func _check_target(caller: Unit, target: Unit, api: String) -> bool:
	if target == null or target._framework_battle != self:
		report_violation(caller, "%s() 的目標不存在" % api)
		return false
	if not target.is_alive():
		_log("[color=gray]%s 的 %s() 目標已經倒下了[/color]" % [_n(caller), api])
		return false
	return true


func _cap(caller: Unit, api: String, amount: int, low: int, high: int) -> int:
	if caller is Boss:
		return maxi(0, amount)
	var capped := clampi(amount, low, high)
	if capped != amount:
		_log("[color=#ffb74d]%s 的 %s(%d) 超出範圍，被限制成 %d[/color]" % [_n(caller), api, amount, capped])
	return capped


# ---------------------------------------------------------------- 棋盤查詢

## 還活著的角色，照行動順序（前排 → 後排、左 → 右）
func get_alive(team: int) -> Array[Unit]:
	var alive: Array[Unit] = []
	for unit: Unit in teams[team]:
		if unit.is_alive():
			alive.append(unit)
	return alive


func units_in_row(team: int, row: int) -> Array[Unit]:
	var units: Array[Unit] = []
	for unit: Unit in get_alive(team):
		if unit._framework_cell.y == row:
			units.append(unit)
	return units


func units_in_column(team: int, col: int) -> Array[Unit]:
	var units: Array[Unit] = []
	for unit: Unit in get_alive(team):
		if unit._framework_cell.x == col:
			units.append(unit)
	return units


func adjacent_allies(unit: Unit) -> Array[Unit]:
	var units: Array[Unit] = []
	for ally: Unit in get_alive(unit._framework_team):
		var diff: Vector2i = (ally._framework_cell - unit._framework_cell).abs()
		if diff.x + diff.y == 1:
			units.append(ally)
	return units


# ---------------------------------------------------------------- 工具

func _unit_at(team: int, cell: Vector2i) -> Unit:
	for unit: Unit in teams[team]:
		if unit._framework_cell == cell:
			return unit
	return null


func _all_units() -> Array[Unit]:
	var units: Array[Unit] = []
	units.append_array(teams[PLAYER])
	units.append_array(teams[ENEMY])
	return units


func _all_alive() -> Array[Unit]:
	var alive := get_alive(PLAYER)
	alive.append_array(get_alive(ENEMY))
	return alive


func _add_unit(unit: Unit, team: int, cell: Vector2i) -> void:
	unit._framework_battle = self
	unit._framework_team = team
	unit._framework_cell = cell
	_write(unit, "hp", unit.max_hp)
	unit._framework_locked = true
	roster.append(unit)
	# 照行動順序插進去，get_alive() 就不用每次排序
	var list: Array = teams[team]
	var index: int = list.size()
	for i: int in list.size():
		if Rules.cell_order(list[i]._framework_cell) > Rules.cell_order(cell):
			index = i
			break
	list.insert(index, unit)


func _write(unit: Unit, property: StringName, value: Variant) -> void:
	unit._framework_writing = true
	unit.set(property, value)
	unit._framework_writing = false


## 戰鬥紀錄裡的名字，例如「[前排左] 騎士」
func _n(unit: Unit) -> String:
	if unit == null:
		return "？"
	return "[color=%s][lb]%s[rb] %s[/color]" % [TEAM_COLORS[unit._framework_team],
			Rules.cell_name(unit._framework_cell), unit.unit_name]


func _log(text: String) -> void:
	logged.emit(text)
