extends Team
## 階段 2 範例隊伍：只用 deal_damage() 一招，就打得贏 Lv2 刺甲龜。
## 卡關的話可以整個資料夾複製過去，改成自己的 GitHub 帳號再慢慢改。
## 花費 = 30 + 4 × 16 = 94 點


func _init() -> void:
	team_name = "補刀隊"
	github = "example_stage2"
	members = [
		preload("tank.gd"),
		preload("archer.gd"),
		preload("archer_left.gd"),
		preload("archer_right.gd"),
		preload("archer_back.gd"),
	]
