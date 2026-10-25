class_name Healer
extends Mage
## 補師（法師的子類別）：不攻擊，改成每回合幫上下左右相鄰、有受傷的隊友回 attack 點血。
## 不會觸發 on_attack。


func get_role() -> String:
	return "補師"
