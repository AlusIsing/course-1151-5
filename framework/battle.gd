class_name Battle
extends RefCounted
## 戰鬥流程。純邏輯、不碰畫面，擂台和無畫面模擬共用。
##
## 一回合的順序：
##   1. Boss 的 on_round_start
##   2. 雙方前排同時攻擊 → 扣血
##   3. 攻擊者的 on_attack → 受傷者的 on_hurt
##   4. 結算死亡：on_death → 隊友的 on_ally_death → 後面的角色往前補位
##   5. 一方全滅就結束；超過 MAX_ROUNDS 回合算挑戰者輸
##
## 規則細節：
##   - 同一個階段裡，玩家隊伍先、Boss 隊伍後；隊伍內由前排到後排
##   - 血量歸零的角色只會再觸發 on_death，其他事件都不會觸發
##   - 技能造成的傷害會立刻觸發對方的 on_hurt，連鎖最多 MAX_EVENT_DEPTH 層

signal logged(text: String)
signal unit_added(unit: Unit)
signal unit_died(unit: Unit)
signal unit_damaged(unit: Unit, amount: int)
signal unit_healed(unit: Unit, amount: int)
signal finished(result: String)

const PLAYER := 0
const ENEMY := 1
const TEAM_COLORS := ["#7cc4ff", "#ff8a80"]

var teams: Array = [[], []]   # 兩隊還在場上的角色（Array of Unit），最前排在 [0]
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


func _init(player_scripts: Array, boss_script: Script) -> void:
	rng.seed = Rules.SEED
	seed(Rules.SEED)
	for script in player_scripts:
		_add_unit(script.new(), PLAYER)
	_add_unit(boss_script.new(), ENEMY)


# ---------------------------------------------------------------- 流程

func start() -> void:
	_log("[b]=== 戰鬥開始（種子 %d）===[/b]" % Rules.SEED)
	for unit in _all_alive():
		_fire(unit, "on_battle_start", [])
	_resolve_deaths()
	_check_end()


func step() -> void:
	if result != "":
		return
	round_number += 1
	_log("[b]— 第 %d 回合 —[/b]" % round_number)

	for unit in _all_alive():
		if unit is Boss:
			_fire(unit, "on_round_start", [round_number])
	_resolve_deaths()
	if _check_end():
		return

	# 雙方前排同時攻擊：先算好所有命中，再一起扣血
	var hits := []        # [attacker, target, amount]
	var attacks := []     # [attacker, 主要目標]
	for team in [PLAYER, ENEMY]:
		var attacker := _front(team)
		var defender := _front(1 - team)
		if attacker == null or defender == null:
			continue
		var targets: Array[Unit] = [defender]
		var amount := attacker.attack
		var boss := attacker as Boss
		if boss:
			if boss.skip_attack:
				continue
			if boss.pierce:
				targets = get_alive(1 - team)
				amount = boss.pierce_damage
		if amount <= 0:
			continue
		attacks.append([attacker, defender])
		for target in targets:
			hits.append([attacker, target, amount])

	var hurt := []        # [target, 實際傷害, source]
	for hit in hits:
		var dealt := _apply_damage(hit[1], hit[2], hit[0], "攻擊")
		if dealt > 0:
			hurt.append([hit[1], dealt, hit[0]])
	for pair in attacks:
		if pair[0].is_alive():
			_fire(pair[0], "on_attack", [pair[1]])
	for entry in hurt:
		if entry[0].is_alive():
			_fire(entry[0], "on_hurt", [entry[1], entry[2]])

	_resolve_deaths()
	_check_end()


func _resolve_deaths() -> void:
	# on_death 裡的技能可能再打死別人，所以重複結算到沒人死為止
	for _i in 20:
		var dying: Array[Unit] = []
		for unit in _all_units():
			if not unit._framework_dead and unit.hp <= 0:
				dying.append(unit)
		if dying.is_empty():
			return
		for unit in dying:
			unit._framework_dead = true
			_tokens[unit] = []
			_token_budget[unit] = Rules.TOKEN_BUDGET
		for unit in dying:
			_log("%s 倒下了" % _n(unit))
			_fire(unit, "on_death", [])
			for ally in get_alive(unit._framework_team):
				_fire(ally, "on_ally_death", [unit])
		for unit in dying:
			var team: Array = teams[unit._framework_team]
			var index := team.find(unit)
			team.remove_at(index)
			unit_died.emit(unit)
			for token in _tokens[unit]:
				_add_unit(token, unit._framework_team, index)
				index += 1
				unit_added.emit(token)
			_tokens.erase(unit)
			_token_budget.erase(unit)


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


func _apply_damage(target: Unit, amount: int, source: Unit, verb: String) -> int:
	if not target.is_alive() or amount <= 0:
		return 0
	var boss := target as Boss
	if boss:
		amount *= boss.damage_taken_multiplier
	_write(target, "hp", maxi(0, target.hp - amount))
	_log("%s %s %s，造成 %d 傷害（剩 %d）" % [_n(source), verb, _n(target), amount, target.hp])
	unit_damaged.emit(target, amount)
	return amount


# ---------------------------------------------------------------- 戰鬥 API

func api_deal_damage(caller: Unit, target: Unit, amount: int) -> void:
	if not _api_begin(caller, "deal_damage") or not _check_target(caller, target, "deal_damage"):
		return
	amount = _cap(caller, "deal_damage", amount, 1, Rules.DAMAGE_CAP)
	var dealt := _apply_damage(target, amount, caller, "用技能打")
	if dealt > 0 and target.is_alive():
		_fire(target, "on_hurt", [dealt, caller])


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
		report_violation(caller, "%s() 只能在自己的戰鬥事件裡用（on_frame 不行）" % api)
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


# ---------------------------------------------------------------- 工具

func get_alive(team: int) -> Array[Unit]:
	var alive: Array[Unit] = []
	for unit in teams[team]:
		if unit.is_alive():
			alive.append(unit)
	return alive


func _all_units() -> Array[Unit]:
	var units: Array[Unit] = []
	units.append_array(teams[PLAYER])
	units.append_array(teams[ENEMY])
	return units


func _all_alive() -> Array[Unit]:
	var alive := get_alive(PLAYER)
	alive.append_array(get_alive(ENEMY))
	return alive


func _front(team: int) -> Unit:
	var alive := get_alive(team)
	return alive[0] if not alive.is_empty() else null


func _add_unit(unit: Unit, team: int, index := -1) -> void:
	unit._framework_battle = self
	unit._framework_team = team
	_write(unit, "hp", unit.max_hp)
	unit._framework_locked = true
	roster.append(unit)
	if index < 0:
		teams[team].append(unit)
	else:
		teams[team].insert(index, unit)


func _write(unit: Unit, property: StringName, value: Variant) -> void:
	unit._framework_writing = true
	unit.set(property, value)
	unit._framework_writing = false


func _n(unit: Unit) -> String:
	if unit == null:
		return "？"
	return "[color=%s]%s[/color]" % [TEAM_COLORS[unit._framework_team], unit.unit_name]


func _log(text: String) -> void:
	logged.emit(text)
