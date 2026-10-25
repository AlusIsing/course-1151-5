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


## 行動順序：前排 → 後排，同一排由左到右
static func cell_order(cell: Vector2i) -> int:
	return cell.y * GRID_COLS + cell.x
