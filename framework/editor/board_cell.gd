class_name BoardCell
extends PanelContainer
## 陣型編輯器棋盤上的一格。可以把清單裡的角色拖進來，也可以把這格的角色拖到別格或拖回清單。
## 拖放的判斷都交給 FormationEditor。

var editor: FormationEditor
var cell: Vector2i
var label: Label


func _init(p_editor: FormationEditor, p_cell: Vector2i) -> void:
	editor = p_editor
	cell = p_cell
	custom_minimum_size = Vector2(190.0, 112.0)
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	mouse_exited.connect(func() -> void: editor.set_hover_cell(Vector2i(-1, -1)))


func _get_drag_data(_at_position: Vector2) -> Variant:
	return editor.drag_from_cell(cell)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ok: bool = editor.can_drop_on_cell(cell, data)
	editor.set_hover_cell(cell if ok else Vector2i(-1, -1))
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	editor.drop_on_cell(cell, data)
