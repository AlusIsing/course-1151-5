extends Tank

const HURT_LINES := ["就這？", "還敢打我啊？", "後面的別怕，有我在！", "痛是痛，但你更痛。"]

func _init() -> void:
	unit_name = "zyzy0826"
	max_hp = 20
	attack = 0
	grid_position = Vector2i(1, 0)   # 前排中

func on_battle_start() -> void:
	say("全員就位！今天誰也別想越過我。")

func on_hurt(amount: int, source: Unit) -> void:
	if source != null and source.is_alive():
		say(random_pick(HURT_LINES))
		deal_damage(source, 3)

func on_death() -> void:
	say("……接下來，交給你們了。")
