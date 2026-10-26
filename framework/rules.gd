class_name Rules
extends RefCounted
## 所有規則數值集中在這裡，框架、validator、模擬腳本都讀這份。

const SEED := 1151
const MAX_ROUNDS := 30
const MAX_UNITS := 5

# --- 棋盤：每方 3×3，row 0 前排 / 1 中排 / 2 後排，col 0 左 / 1 中 / 2 右 ---
const GRID_ROWS := 3
const GRID_COLS := 3
const ROW_NAMES: Array[String] = ["前排", "中排", "後排"]
const COL_NAMES: Array[String] = ["左", "中", "右"]
const TANK_SHARE_PERCENT := 50  # 坦克替相鄰隊友分擔的傷害比例（無條件捨去）

# --- 職業被動（不用寫程式，選了職業就有；召喚的分身和 Boss 沒有）---
const WARRIOR_CHARGE := 2       # 戰士「衝鋒」：每場第一次普攻傷害 +2
const ARCHER_WEAK_SPOT := 1     # 射手「弱點射擊」：普攻血量低於一半的目標傷害 +1
const MAGE_ENERGY_REGEN := 4    # 法師「法力湧流」：每回合回復的能量（補師沒有）
const HEALER_CLEANSE := 1       # 補師「淨化」：普通治療時，順便移除目標幾層中毒
# 刺客「閃避」：每場第一次被普攻打中時不受傷害；坦克「掩護」見 TANK_SHARE_PERCENT

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

# --- 能量：技能 API 要花能量，普攻和補師的普通治療免費（Boss 不用能量）---
const ENERGY_START := 3        # 戰鬥開始時的能量
const ENERGY_REGEN := 3        # 每回合開始回復
const ENERGY_MAX := 6          # 最多累積
const BUFF_ENERGY_PER_POINT := 2   # buff_attack 每加 1 攻擊花 2 能量（召喚 token 不花能量）

# --- 流派：順序和 Unit.School 一樣（NONE、VENOM、AEGIS、BLOOD、NECRO）---
const SCHOOL_NAMES: Array[String] = ["無", "劇毒", "聖盾", "狂血", "死靈"]
const SCHOOL_ICONS: Array[String] = ["", "🧪", "🛡️", "🔥", "💀"]
const SCHOOL_TIERS: Array[int] = [2, 4]   # 開場時同流派幾隻啟動加成
const OFF_SCHOOL_COST := 2     # 用別的流派的 API（包含沒有流派）要花兩倍能量
const SHIELD_MAX := 10         # 每隻角色的護盾上限
# 下面這些數值用 tools/balance.gd 調過（規格原本是：毒傷 +1、聖盾 4 隻 6 點、靈魂能量 5 點）
const VENOM_TICK_BONUS := 2    # 劇毒 2 隻：我方施加的毒傷每回合 +2
const AEGIS_SHIELD: Array[int] = [3, 4]   # 聖盾 2 隻 / 4 隻的開場護盾（不疊加）
const BLOOD_LIFESTEAL := 1     # 狂血 2 隻：普攻命中後回血
const BLOOD_FURY := 2          # 狂血 4 隻：血量低於一半時普攻 +2
const NECRO_SOUL := 6          # 死靈 2 隻：on_death 期間可用的靈魂能量
const NECRO_BLAST := 1         # 死靈 4 隻：死亡時對全體敵人的傷害


## 流派加成的說明，[2 隻的效果, 4 隻的效果]，數字直接讀上面的常數
static func school_bonus_text(school: int) -> Array[String]:
	match school:
		1:
			return ["我方施加的毒傷每回合 +%d" % VENOM_TICK_BONUS, "中毒的敵人無法被治療"]
		2:
			return ["開場全隊獲得 %d 點護盾" % AEGIS_SHIELD[0], "開場全隊獲得 %d 點護盾" % AEGIS_SHIELD[1]]
		3:
			return ["普通攻擊命中後回復 %d 血" % BLOOD_LIFESTEAL, "血量低於一半時攻擊 +%d" % BLOOD_FURY]
		4:
			return ["死靈角色死亡時獲得 %d 點靈魂能量" % NECRO_SOUL, "死靈角色死亡時對全體敵人造成 %d 點傷害" % NECRO_BLAST]
	return []

## 職業被動的說明，role 是 get_role() 回傳的職業名稱
static func passive_text(role: String) -> String:
	match role:
		"戰士":
			return "衝鋒：每場第一次普攻傷害 +%d" % WARRIOR_CHARGE
		"坦克":
			return "掩護：替上下左右相鄰的隊友分擔 %d%% 傷害" % TANK_SHARE_PERCENT
		"射手":
			return "弱點射擊：普攻血量低於一半的目標傷害 +%d" % ARCHER_WEAK_SPOT
		"法師":
			return "法力湧流：每回合回復 %d 能量（一般是 %d）" % [MAGE_ENERGY_REGEN, ENERGY_REGEN]
		"補師":
			return "淨化：普通治療時順便移除 %d 層中毒" % HEALER_CLEANSE
		"刺客":
			return "閃避：每場第一次被普攻打中時不受傷害"
	return ""

const TEAMS_DIR := "res://teams"      # 每個人一個資料夾，用 GitHub 帳號命名
const DEFAULT_TEAM := "example"
const DEFAULT_BOSS := "dummy"
const PREVIEW_SCENE := "res://framework/preview/team_preview.tscn"
const ARENA_SCENE := "res://framework/arena_screen.tscn"
const MATCHES_PATH := "res://framework/matches.gd"
const BOSSES := {
	"dummy": "res://bosses/dummy/boss.gd",
	"lv1": "res://bosses/lv1/boss.gd",
	"lv2": "res://bosses/lv2/boss.gd",
	"lv3": "res://bosses/lv3/boss.gd",
}


static func unit_cost(max_hp: int, attack: int) -> int:
	return max_hp * HP_COST + attack * ATTACK_COST


static func team_dir(github: String) -> String:
	return "%s/%s" % [TEAMS_DIR, github]


static func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_COLS and cell.y >= 0 and cell.y < GRID_ROWS


## 格子名稱，例如 Vector2i(0, 0) →「前排左」
static func cell_name(cell: Vector2i) -> String:
	if not is_valid_cell(cell):
		return "場外"
	return ROW_NAMES[cell.y] + COL_NAMES[cell.x]


## 格子名稱加上可以直接照抄的座標，例如 Vector2i(0, 0) →「前排左 Vector2i(0, 0)」
static func cell_label(cell: Vector2i) -> String:
	return "%s Vector2i(%d, %d)" % [cell_name(cell), cell.x, cell.y]


## 流派加成的等級：0 沒有、1 是 2 隻加成、2 是 4 隻加成
static func school_tier(count: int) -> int:
	var tier: int = 0
	for need: int in SCHOOL_TIERS:
		if count >= need:
			tier += 1
	return tier


## 行動順序：前排 → 後排，同一排由左到右
static func cell_order(cell: Vector2i) -> int:
	return cell.y * GRID_COLS + cell.x
