class_name Warrior
extends Unit
## 戰士（近戰）：只能攻擊敵方最前排，優先打同一行。
## 直接 extends Unit 的角色也是這樣打，這個類別只是讓職業寫得更清楚。


func get_role() -> String:
	return "戰士"
