extends Mage
## 劇毒法師（共用父類別，本身不上場）
## 每次行動把能量全部拆成「1 點傷害」的毒：劇毒 2 隻以上每層毒每回合 +2，
## 所以 1 點能量 = 1 回合 × (1 + 2) = 3 點傷害，而且毒無視護盾。
## 法師每回合回 4 能量，比其他職業多 1。
## 選目標：優先把毒疊在「下一次毒發就會死」所需層數最少的敵人身上，一隻一隻毒死。

const POISON_TICK := 3   # 1 點毒 + 劇毒加成 2


func _init() -> void:
	max_hp = 18
	attack = 1     # 至少 1 才會普攻、觸發 on_attack
	school = School.VENOM
	color = Color("#8bc34a")


func on_battle_start() -> void:
	_spread_poison()


func on_attack(_target: Unit) -> void:
	_spread_poison()


## 把能量平分成最多 3 層毒（每個事件最多 3 次 API），每層 1 點傷害、持續 n 回合
func _spread_poison() -> void:
	var budget: int = get_energy()
	for calls_left: int in range(3, 0, -1):
		if budget <= 0:
			return
		var target: Unit = _pick_poison_target()
		if target == null:
			return
		var turns: int = ceili(float(budget) / calls_left)
		if poison(target, 1, turns):
			budget -= turns


## 還差最少層毒就能毒死的敵人；大家都已經夠毒死了，就挑血最多的
func _pick_poison_target() -> Unit:
	var best: Unit = null
	var best_need: int = 999
	var tankiest: Unit = null
	for enemy: Unit in get_enemies():
		var per_tick: int = POISON_TICK - POISON_TICK / 2 if _is_guarded(enemy) else POISON_TICK
		var need: int = ceili(float(enemy.hp) / per_tick) - enemy.get_poison_stacks()
		if need > 0 and need < best_need:
			best = enemy
			best_need = need
		if tankiest == null or enemy.hp > tankiest.hp:
			tankiest = enemy
	return best if best != null else tankiest


## 敵人旁邊（上下左右）有活著的敵方坦克時，毒傷會被分擔一半
func _is_guarded(enemy: Unit) -> bool:
	if enemy.get_role() == "坦克":
		return false
	for other: Unit in get_enemies():
		if other.get_role() == "坦克":
			var diff: Vector2i = other.get_grid_position() - enemy.get_grid_position()
			if absi(diff.x) + absi(diff.y) == 1:
				return true
	return false
