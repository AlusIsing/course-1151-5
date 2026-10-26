extends Tank
## zyzy0826（死靈坦克）：前排中，掩護相鄰隊友；被打就反擊，殘血時用能量自救。
## 倒下時：靈魂能量爆發，對血最少的敵人打 5 + 5，再召喚分身。
## 花費 = 20 + 2 × 0 = 20 點

const HURT_LINES := ["就這？", "還敢打我啊？", "後面的別怕，有我在！", "痛是痛，但你更痛。"]


func _init() -> void:
	unit_name = "zyzy0826"
	max_hp = 20
	attack = 0
	color = Color("#455a64")
	grid_position = Vector2i(1, 0)   # 前排中
	school = School.NECRO


func on_battle_start() -> void:
	say("全員就位！今天誰也別想越過我。")


func on_hurt(_amount: int, source: Unit) -> void:
	if is_alive() and hp <= 5 and get_energy() > 0 and get_poison_stacks() == 0:
		say("還沒結束！")
		heal(self, mini(5, get_energy()))      # 瀕死自救
		return
	if source != null and source.is_alive() and get_energy() >= 3:
		say(random_pick(HURT_LINES))
		deal_damage(source, 3)                 # 反擊，會觸發對方的 on_hurt（連鎖）


func on_death() -> void:
	var target := _weakest_enemy()
	if target != null:
		deal_damage(target, 5)                 # 靈魂爆發 第一擊
		if not target.is_alive():
			target = _weakest_enemy()
		if target != null and get_energy() > 0:
			deal_damage(target, mini(5, get_energy()))   # 靈魂爆發 第二擊（剩多少能量打多少）
	summon_token(4, 3)                         # 亡魂分身（上限 hp + 2×attack ≤ 10）


func _weakest_enemy() -> Unit:
	var best: Unit = null
	for e: Unit in get_enemies():
		if best == null or e.hp < best.hp:
			best = e
	return best
