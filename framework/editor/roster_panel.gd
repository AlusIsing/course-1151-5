class_name RosterPanel
extends PanelContainer
## 陣型編輯器左邊的角色清單。把棋盤上的角色拖回這裡就會移除。

var editor: FormationEditor


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return editor != null and editor.can_drop_on_roster(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	editor.drop_on_roster(data)
