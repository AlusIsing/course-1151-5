class_name Rules
extends RefCounted
## 所有規則數值集中在這裡，框架、validator、模擬腳本都讀這份。

const SEED := 1151
const MAX_ROUNDS := 30
const MAX_UNITS := 5

# --- 預算：cost = max_hp × HP_COST + attack × ATTACK_COST ---
const BUDGET := 100
const HP_COST := 1
const ATTACK_COST := 2
const MAX_HP_MIN := 1
const MAX_HP_MAX := 40
const ATTACK_MIN := 0
const ATTACK_MAX := 10

# --- 戰鬥 API 上限（Boss 不受限）---
const DAMAGE_CAP := 5          # deal_damage 每次 1–5
const HEAL_CAP := 5            # heal 每次 1–5
const BUFF_CAP := 3            # buff_attack 每次 1–3
const ATTACK_LIMIT := 15       # buff 後 attack 最多 15
const TOKEN_BUDGET := 10       # 每次 on_death 召喚的 token 總共 hp + 2×attack ≤ 10
const CALLS_PER_EVENT := 3     # 每隻角色每個事件最多呼叫 3 次 API
const MAX_EVENT_DEPTH := 3     # 事件連鎖最多 3 層

const TEAM_PATH := "res://my_team/team.gd"
const BOSSES := {
	"dummy": "res://bosses/dummy.gd",
	"lv1": "res://bosses/boss_lv1.gd",
	"lv2": "res://bosses/boss_lv2.gd",
	"lv3": "res://bosses/boss_lv3.gd",
}


static func unit_cost(max_hp: int, attack: int) -> int:
	return max_hp * HP_COST + attack * ATTACK_COST
