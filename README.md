# 集合！Vibe 出你的自走棋物件大隊

用 Godot 4 做的迷你自走棋。你的任務是**請 AI 幫你寫角色**，組成一支隊伍去打倒 Boss。

一路上你會用到物件導向的幾個核心概念：

| 概念 | 在這個專案裡長什麼樣子 |
|---|---|
| 繼承 | 每個角色都 `extends Unit` |
| 覆寫 | 覆寫 `on_hurt()`、`on_death()` 這些事件，做出角色的技能 |
| 多型 | 同一場戰鬥裡，每隻角色對同一個事件的反應都不一樣 |
| 封裝 | 不能直接改 `hp`，只能透過 `deal_damage()`、`heal()` |
| 幀與 delta | 用 `on_frame(delta)` 做動畫，邏輯和畫面分開 |

## 快速開始

1. 安裝 **Godot 4.7**
2. 用 Godot 打開這個資料夾（選 `project.godot`）
3. 按 **F5**，看範例隊伍打木樁

畫面下方是**戰鬥紀錄**，每一次攻擊、技能、倒下都會寫在這裡。角色沒照你想的動，先來這裡找原因。

| 按鍵 | 功能 |
|---|---|
| R | 重新開始 |
| 空白鍵 | 暫停 / 繼續 |
| 1 / 2 / 3 | 1 倍 / 2 倍 / 4 倍速 |

## 戰鬥規則

- 雙方各排一列，**最前面的角色互打**
- 每回合：雙方前排同時攻擊 → 扣血 → 血量歸零的角色倒下 → 後面的角色往前補位
- 一方全滅就結束；**超過 30 回合**還沒打倒 Boss 算你輸，同歸於盡也算你輸
- 隨機用固定種子，同樣的隊伍打同樣的 Boss，結果永遠一樣

### 預算

每隊**最多 5 隻**，**總預算 100 點**：

```
花費 = max_hp + 2 × attack
```

| 屬性 | 範圍 |
|---|---|
| `max_hp` | 1–40 |
| `attack` | 0–10 |

技能不花點數，但戰鬥 API 有數值上限（見下方）。超過預算或違規的隊伍，按 F5 後會顯示「無法上場」，戰鬥紀錄會列出原因。

## 寫一隻角色

在 `my_team/` 新增一個 `.gd` 檔：

```gdscript
extends Unit
## 小護士：受傷時，幫後面的隊友回 2 血

func _init() -> void:
	unit_name = "小護士"
	max_hp = 16
	attack = 3
	color = Color("#ff9ecf")

func on_hurt(amount: int, source: Unit) -> void:
	var allies := get_allies()
	var me := get_slot()
	if me + 1 < allies.size():
		heal(allies[me + 1], 2)
```

然後把它加進 `my_team/team.gd`：

```gdscript
const BOSS := "dummy"

const MEMBERS := [
	preload("res://my_team/nurse.gd"),   # 寫在最前面的站前排
	preload("res://examples/knight.gd"),
]
```

`examples/` 裡有史萊姆和騎士可以參考。

### 事件（覆寫這些來做技能）

| 方法 | 什麼時候觸發 |
|---|---|
| `on_battle_start()` | 戰鬥開始時 |
| `on_attack(target)` | 自己攻擊之後 |
| `on_hurt(amount, source)` | 自己受傷之後 |
| `on_death()` | 自己倒下時 |
| `on_ally_death(ally)` | 有隊友倒下時 |
| `on_frame(delta)` | 每一幀，**只能做畫面效果** |

觸發順序：玩家隊伍先、Boss 後；同一隊由前排到後排。血量歸零的角色只會再觸發 `on_death`。

### 戰鬥 API

| 方法 | 效果 | 上限 |
|---|---|---|
| `deal_damage(target, amount)` | 造成傷害 | 每次 1–5 |
| `heal(target, amount)` | 回血 | 每次 1–5，不超過 `max_hp` |
| `buff_attack(target, amount)` | 加攻擊 | 每次 1–3，最多加到 15 |
| `summon_token(hp, attack)` | 召喚沒有技能的分身到自己的位置 | 只能在 `on_death` 用，合計 `hp + 2×attack ≤ 10` |
| `say(text)` | 在戰鬥紀錄說一句話 | — |

- 每隻角色在**每個事件裡最多呼叫 3 次** API
- 技能造成的傷害會觸發對方的 `on_hurt`，連鎖最多 3 層
- 超出範圍的數值會被自動限制，戰鬥紀錄會用橘字提醒

### 查詢

| 方法 | 回傳 |
|---|---|
| `get_allies()` | 還活著的隊友（包含自己），最前排在 `[0]` |
| `get_enemies()` | 還活著的敵人，最前排在 `[0]` |
| `get_slot()` | 自己站在第幾個位置（0 = 最前排） |
| `get_round()` | 現在第幾回合 |
| `is_alive()` | 是否還活著 |
| `random_int(a, b)`、`random_pick(array)` | 固定種子的隨機 |

### 外觀

`color`、`body_radius`、`status_text`、`position`、`modulate`、`scale` 這些都可以隨便改，不影響戰鬥。動畫請寫在 `on_frame(delta)`：

```gdscript
var t := 0.0

func on_frame(delta: float) -> void:
	t += delta
	position.y = sin(t * 4.0) * 6.0   # 上下浮動
```

## 不能做的事

上場前會掃描你的程式碼，出現下面這些就不能上場：

- `_process`、`_physics_process`：動畫請改用 `on_frame(delta)`
- 在 `on_frame` 裡呼叫戰鬥 API
- `get_tree`、`get_node`、`get_parent`、`$節點`：請用 `get_allies()` / `get_enemies()`
- `set()`、`call()` 這類方法，或任何 `_framework` 開頭的東西
- `randi()`、`randf()`、`shuffle()` 等內建隨機：請用 `random_int()` / `random_pick()`
- `queue_free()`、`add_child()` 等新增或刪除節點的方法
- 繼承 `Boss`

戰鬥中直接寫 `enemy.hp = 0` 也不會成功，戰鬥紀錄會出現紅字。想想看為什麼要這樣設計？

## Boss

在 `my_team/team.gd` 把 `BOSS` 改成想挑戰的對象。每隻 Boss 的能力寫在 `bosses/` 資料夾裡的檔案開頭，打之前先讀一下。

| `BOSS` | 名稱 |
|---|---|
| `"dummy"` | 木樁（練習用） |
| `"lv1"` | 史萊姆王 |
| `"lv2"` | 刺甲龜 |
| `"lv3"` | 雷神 |

沒有哪一種隊伍能通吃所有 Boss。打輸了就看戰鬥紀錄，調整站位、數值或技能再試一次。

## 專案結構

```
├── framework/          ← 框架，不要改
│   ├── rules.gd        ← 所有規則數值
│   ├── unit.gd         ← Unit 父類別
│   ├── boss.gd         ← Boss 父類別
│   ├── battle.gd       ← 戰鬥流程
│   ├── validator.gd    ← 預算和作弊檢查
│   ├── arena.tscn      ← 擂台（主場景）
│   └── simulate.gd     ← 無畫面模擬
├── bosses/             ← Boss
├── examples/           ← 範例角色
└── my_team/            ← 你只需要改這裡
    └── team.gd         ← 隊伍名單、要挑戰的 Boss
```

## 無畫面模擬

不開視窗、直接在終端機印出整場戰鬥紀錄，調數值時很方便：

```sh
godot --headless --script res://framework/simulate.gd            # 打 team.gd 設定的 Boss
godot --headless --script res://framework/simulate.gd -- lv3     # 指定 Boss
```

結束代碼：`0` 勝利、`2` 落敗、`1` 隊伍沒通過檢查。
