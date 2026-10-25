class_name RosterEntry
extends PanelContainer
## 陣型編輯器左邊清單裡的一隻角色，拖到棋盤上就會放上去。
## 從棋盤拖回來放在這上面，一樣會把那隻移除。

var editor: FormationEditor
var path: String


func _init(p_editor: FormationEditor, p_path: String, text: String, color: Color) -> void:
	editor = p_editor
	path = p_path
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.65)
	style.border_color = color
	style.border_width_left = 6
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8.0)
	add_theme_stylebox_override("panel", style)
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	var label: Label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func _get_drag_data(_at_position: Vector2) -> Variant:
	return editor.drag_from_roster(path)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return editor.can_drop_on_roster(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	editor.drop_on_roster(data)
