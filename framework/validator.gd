class_name Validator
extends RefCounted
## 上場前的檢查：點數預算 + 用文字掃描學員的 .gd 擋掉作弊寫法。
## 回傳錯誤訊息陣列，空陣列代表通過。

const BANNED := [
	[r"\b_process\b|\b_physics_process\b",
		"不能用 _process / _physics_process，畫面效果請寫在 on_frame(delta)"],
	[r"\bget_tree\b|\bget_node\b|\bget_parent\b|\bget_child(ren)?\b|\bfind_child(ren)?\b|\$[\w\"]",
		"不能用 get_tree / get_node 這類方法去抓別的物件，請用 get_allies() / get_enemies()"],
	[r"\b_framework",
		"不能碰框架內部（_framework 開頭的東西）"],
	[r"\b(set|set_deferred|set_indexed|call|callv|call_deferred|set_script)\s*\(|\bCallable\s*\(|\bExpression\b",
		"不能用 set() / call() 這類方法繞過 API"],
	[r"\b(free|queue_free|add_child|remove_child|reparent)\s*\(",
		"不能新增、移除或刪除節點"],
	[r"\b(randi|randf|randi_range|randf_range|randfn|randomize|seed)\s*\(|\.(pick_random|shuffle)\s*\(|\bRandomNumberGenerator\b",
		"不能用內建隨機（結果會不固定），請用 random_int() / random_pick()"],
	[r"\bBoss\b",
		"學員的角色不能用 Boss 類別"],
]
const FRAME_FORBIDDEN := r"\b(deal_damage|heal|buff_attack|summon_token|say)\s*\("


static func check_team(members: Array) -> Array[String]:
	var errors: Array[String] = []
	if members.is_empty():
		errors.append("隊伍是空的，請在 my_team/team.gd 的 MEMBERS 加入角色")
		return errors
	if members.size() > Rules.MAX_UNITS:
		errors.append("隊伍最多 %d 隻，現在有 %d 隻" % [Rules.MAX_UNITS, members.size()])

	var total := 0
	var receipt: Array[String] = []
	var scanned := {}
	for i in members.size():
		var script := members[i] as Script
		if script == null:
			errors.append("MEMBERS 第 %d 個不是角色腳本" % (i + 1))
			continue
		# 整條繼承鏈都要掃（學員可能繼承自己或範例的角色）
		var current := script
		while current != null and not current.resource_path.begins_with("res://framework/"):
			if not scanned.has(current.resource_path):
				scanned[current.resource_path] = true
				errors.append_array(check_source(current.resource_path))
			current = current.get_base_script()

		var unit = script.new()
		if not unit is Unit:
			errors.append("%s 要 extends Unit" % _short(script.resource_path))
			if unit is Node:
				unit.free()
			continue
		if unit is Boss:
			errors.append("%s 不能繼承 Boss" % _short(script.resource_path))
		var label := "%s（%s）" % [unit.unit_name, _short(script.resource_path)]
		if unit.max_hp < Rules.MAX_HP_MIN or unit.max_hp > Rules.MAX_HP_MAX:
			errors.append("%s：max_hp 要在 %d–%d 之間，現在是 %d"
					% [label, Rules.MAX_HP_MIN, Rules.MAX_HP_MAX, unit.max_hp])
		if unit.attack < Rules.ATTACK_MIN or unit.attack > Rules.ATTACK_MAX:
			errors.append("%s：attack 要在 %d–%d 之間，現在是 %d"
					% [label, Rules.ATTACK_MIN, Rules.ATTACK_MAX, unit.attack])
		var cost := Rules.unit_cost(unit.max_hp, unit.attack)
		total += cost
		receipt.append("%s %d+2×%d=%d" % [unit.unit_name, unit.max_hp, unit.attack, cost])
		unit.free()

	if total > Rules.BUDGET:
		errors.append("總花費 %d 點，超過預算 %d 點：%s" % [total, Rules.BUDGET, "、".join(receipt)])
	return errors


## 總花費明細，例如「騎士 28 + 史萊姆 18 = 46 / 100」
static func describe_cost(members: Array) -> String:
	var parts: Array[String] = []
	var total := 0
	for script in members:
		var unit = script.new()
		var cost := Rules.unit_cost(unit.max_hp, unit.attack)
		parts.append("%s %d" % [unit.unit_name, cost])
		total += cost
		unit.free()
	return "%s = %d / %d 點" % [" + ".join(parts), total, Rules.BUDGET]


static func check_source(path: String) -> Array[String]:
	var errors: Array[String] = []
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		errors.append("讀不到 %s" % _short(path))
		return errors

	var lines := text.split("\n")
	var frame_indent := -1    # >= 0 代表正在 on_frame 的函式本體裡
	var func_regex := RegEx.create_from_string(r"^(\s*)func\s+(\w+)")
	var frame_regex := RegEx.create_from_string(FRAME_FORBIDDEN)
	for i in lines.size():
		var code := _strip(lines[i])
		if code.strip_edges() == "":
			continue
		var indent := code.length() - code.lstrip(" \t").length()
		if frame_indent >= 0 and indent <= frame_indent:
			frame_indent = -1
		var func_match := func_regex.search(code)
		if func_match and func_match.get_string(2) == "on_frame":
			frame_indent = func_match.get_string(1).length()

		var where := "%s 第 %d 行" % [_short(path), i + 1]
		for rule in BANNED:
			if RegEx.create_from_string(rule[0]).search(code):
				errors.append("%s：%s" % [where, rule[1]])
		if frame_indent >= 0 and frame_regex.search(code):
			errors.append("%s：on_frame 只能做畫面效果，不能呼叫戰鬥 API" % where)
	return errors


## 去掉字串內容和註解，避免誤判
static func _strip(line: String) -> String:
	var result := ""
	var quote := ""
	var i := 0
	while i < line.length():
		var c := line[i]
		if quote != "":
			if c == "\\":
				i += 1
			elif c == quote:
				quote = ""
				result += c
		elif c == "\"" or c == "'":
			quote = c
			result += c
		elif c == "#":
			break
		else:
			result += c
		i += 1
	return result


static func _short(path: String) -> String:
	return path.trim_prefix("res://")
