class_name Boss
extends Unit
## Boss 的父類別（講師用，學員的角色不能繼承這個）。
##
## Boss 呼叫戰鬥 API 時不受數值上限和呼叫次數限制，
## 另外可以在 on_round_start() 設定下面這些欄位來改變這回合的行為。

var skip_attack := false            # true：這回合不普攻
var pierce := false                 # true：這回合普攻打整排
var pierce_damage := 0              # 打整排時每隻受到的傷害
var damage_taken_multiplier := 1    # 受到的傷害倍率


func _init() -> void:
	body_radius = 52.0
	color = Color("#d9534f")


## 每回合開始、攻擊之前呼叫
func on_round_start(_round_number: int) -> void: pass
