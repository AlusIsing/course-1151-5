extends Team
## 劇毒引爆隊：5 劇毒陣容，由前中排疊滿毒素，再由後排引爆者完成終結

func _init() -> void:
	team_name = "劇毒引爆隊"
	github = "zyzy0826"
	members = [
		preload("tank.gd"),
		preload("warrior.gd"),
		preload("archer.gd"),
		preload("assassin.gd"),
		preload("detonator.gd"),
	]
