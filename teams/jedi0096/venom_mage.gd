extends Mage
## 劇毒法師（共用父類別，本身不上場）：把能量全部拆成「1 點傷害」的毒。
## 劇毒 2 隻以上每層毒每回合 +2，所以 1 點能量 = 3 點傷害，而且毒無視護盾。
## 選目標：優先毒「毒發後剩最少血」的敵人，已經夠毒死的就換下一隻，不浪費毒。


func on_battle_start() -> void:
	_spread_poison()


func on_attack(_target: Unit) -> void:
	_spread_poison()


## 能量平分成最多 3 層毒（每個事件最多 3 次 API）
func _spread_poison() -> void:
	var budget: int = get_energy()
	for calls_left: int in range(3, 0, -1):
		if budget <= 0:
			return
		var target: Unit = null
		var best_left: int = 999
		for e: Unit in get_enemies():
			var left: int = e.hp - 3 * e.get_poison_stacks()   # 毒發後還剩多少血
			if left > 0 and left < best_left:
				target = e
				best_left = left
		if target == null:
			return
		var turns: int = ceili(float(budget) / calls_left)
		if poison(target, 1, turns):
			budget -= turns
