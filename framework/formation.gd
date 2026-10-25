class_name Formation
extends RefCounted
## 一隊的陣型：哪隻角色站在哪一格。存成 formation.json：
##
##     {
##         "boss": "dummy",
##         "units": [
##             {"script": "res://teams/example/knight.gd", "col": 0, "row": 0},
##             {"script": "res://teams/example/archer.gd", "col": 1, "row": 2}
##         ]
##     }
##
## row：0 前排、1 中排、2 後排；col：0 左、1 中、2 右。
## "boss" 只有玩家隊伍有，記住上次在編輯器選的 Boss，可以省略。

const FILE_NAME := "formation.json"


class Slot:
	var path: String
	var cell: Vector2i

	func _init(p_path: String, p_cell: Vector2i) -> void:
		path = p_path
		cell = p_cell


var slots: Array[Slot] = []
var boss_key: String = ""
var errors: Array[String] = []   # 讀檔時發生的錯誤


static func load_dir(dir: String) -> Formation:
	var formation: Formation = Formation.new()
	var path: String = "%s/%s" % [dir, FILE_NAME]
	if not FileAccess.file_exists(path):
		formation.errors.append("找不到 %s，請先用陣型編輯器存檔" % path.trim_prefix("res://"))
		return formation
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		formation.errors.append("%s 不是正確的 JSON" % path.trim_prefix("res://"))
		return formation
	formation.boss_key = str(data.get("boss", ""))
	var units: Variant = data.get("units", [])
	if not units is Array:
		formation.errors.append("%s 的 \"units\" 要是陣列" % path.trim_prefix("res://"))
		return formation
	for entry: Variant in units:
		if not entry is Dictionary or not entry.has("script"):
			formation.errors.append("%s 有一筆角色資料格式不對：%s" % [path.trim_prefix("res://"), str(entry)])
			continue
		var cell: Vector2i = Vector2i(int(entry.get("col", -1)), int(entry.get("row", -1)))
		formation.slots.append(Slot.new(str(entry["script"]), cell))
	return formation


func save_dir(dir: String) -> Error:
	var units: Array[Dictionary] = []
	for slot: Slot in sorted_slots():
		units.append({"script": slot.path, "col": slot.cell.x, "row": slot.cell.y})
	var data: Dictionary = {"units": units}
	if boss_key != "":
		data["boss"] = boss_key
	var file: FileAccess = FileAccess.open("%s/%s" % [dir, FILE_NAME], FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t", false) + "\n")
	return OK


func copy() -> Formation:
	var other: Formation = Formation.new()
	other.boss_key = boss_key
	other.errors = errors.duplicate()
	for slot: Slot in slots:
		other.slots.append(Slot.new(slot.path, slot.cell))
	return other


func slot_at(cell: Vector2i) -> Slot:
	for slot: Slot in slots:
		if slot.cell == cell:
			return slot
	return null


## 依照行動順序（前排 → 後排、左 → 右）排好的格子
func sorted_slots() -> Array[Slot]:
	var result: Array[Slot] = slots.duplicate()
	result.sort_custom(func(a: Slot, b: Slot) -> bool: return Rules.cell_order(a.cell) < Rules.cell_order(b.cell))
	return result


## 載入每一格的腳本（順序同 sorted_slots），載入失敗的那格是 null
func load_scripts() -> Array[Script]:
	var scripts: Array[Script] = []
	for slot: Slot in sorted_slots():
		var script: Script = null
		if ResourceLoader.exists(slot.path):
			script = load(slot.path) as Script
		scripts.append(script)
	return scripts
