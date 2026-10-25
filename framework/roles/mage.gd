class_name Mage
extends Unit
## 法師：攻擊敵方同一行（同一直行）的所有角色，每隻都受到 attack 點傷害。
## 同一行沒有敵人時，改打最近的一行（一樣近就打左邊）。


func get_role() -> String:
	return "法師"
