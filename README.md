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
3. 按 **F5** 打開**陣型編輯器**，上面選隊伍 `example`、Boss 選 `dummy`，按「試打」

### 陣型編輯器

- 左邊是 `teams/<隊伍名字>/` 底下的角色，**拖到右邊的 3×3 棋盤**就會上場
- 棋盤上的角色可以拖到別格（有人就交換），拖回左邊清單就移除
- 右上角即時顯示用掉的預算；**超過預算不能存檔**
- 「存檔」把陣型存成 `teams/<隊伍名字>/formation.json`
- 「試打」直接用目前的陣型（不用先存檔）去挑戰選好的 Boss
- 新增或修改角色腳本之後，按「重新讀取」更新清單

### 擂台

上半部是 Boss 的棋盤、下半部是你的棋盤，兩邊的前排面對面。右邊是**戰鬥紀錄**，每一次攻擊、技能、倒下都會寫在這裡，名字前面會標格子，例如「[前排左] 騎士 攻擊 [前排中] 木樁」。角色沒照你想的動，先來這裡找原因。

| 按鍵 | 功能 |
|---|---|
| R | 重新開始 |
| Esc | 回陣型編輯器 |
| 空白鍵 | 暫停 / 繼續 |
| 1 / 2 / 3 | 1 倍 / 2 倍 / 4 倍速 |

## 戰鬥規則

- 雙方各有 **3×3 棋盤**：前排、中排、後排，每排有左、中、右三格。角色站好就**不會移動**
- 每回合每隻角色輪流行動一次，**順序固定**：我方先、Boss 隊伍後；同一隊從前排到後排、每排從左到右。輪到時已經倒下的角色不會行動
- 一回合結束時結算倒下的角色；一方全滅就結束；**超過 30 回合**還沒打倒 Boss 算你輸，同歸於盡也算你輸
- 隨機用固定種子，同樣的陣型打同樣的 Boss，結果永遠一樣

### 職業

角色 `extends` 哪個職業，就照那個職業的規則普攻。直接 `extends Unit` 的角色算戰士。

| 職業 | 繼承 | 普攻 |
|---|---|---|
| 戰士 | `Warrior`（或 `Unit`） | 近戰：打敵方**最前排**，優先打**同一行** |
| 坦克 | `Tank` | 近戰，同戰士；另外替**上下左右相鄰**的隊友分擔 **50%** 傷害 |
| 射手 | `Archer` | 遠程：可以打**任何一格**，預設打血最少的；覆寫 `choose_target(enemies)` 自己挑 |
| 法師 | `Mage` | 打敵方**同一行的所有角色** |
| 補師 | `Healer`（法師的子類別） | 不攻擊，幫**相鄰**有受傷的隊友回 `attack` 點血 |
| 刺客 | `Assassin` | 打敵方**最後排**，優先打**同一行** |

- 「最前排」「最後排」指**還有角色活著**的那一排：前排全滅，近戰就改打中排
- 「同一行」沒有敵人時，改打**最近的一行**，一樣近就打左邊
- 補師不會觸發 `on_attack`；坦克分擔的傷害會觸發坦克自己的 `on_hurt`

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

在 `teams/my_team/` 新增一個 `.gd` 檔：

```gdscript
extends Unit
## 小護士：受傷時，幫相鄰的隊友各回 1 血

func _init() -> void:
	unit_name = "小護士"
	max_hp = 16
	attack = 3
	color = Color("#ff9ecf")

func on_hurt(amount: int, source: Unit) -> void:
	for ally in get_adjacent_allies():
		heal(ally, 1)
```

存檔後回到陣型編輯器按「重新讀取」，它就會出現在左邊清單，拖到棋盤上就能上場。

想換職業就改 `extends`，例如 `extends Archer`。`teams/example/` 裡每種職業都有範例可以參考。

### formation.json

陣型編輯器存出來的檔案長這樣，也可以直接手改：

```json
{
	"boss": "dummy",
	"units": [
		{ "script": "res://teams/my_team/nurse.gd", "col": 1, "row": 0 }
	]
}
```

- `row`：0 前排、1 中排、2 後排；`col`：0 左、1 中、2 右
- `boss`：上次在編輯器選的 Boss，按 F6 直接開擂台或用無畫面模擬時會用它

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
| `get_allies()` | 還活著的隊友（包含自己），照行動順序排，最前排在前面 |
| `get_enemies()` | 還活著的敵人，照行動順序排 |
| `get_slot()` | 自己在 `get_allies()` 裡排第幾個 |
| `get_grid_position()` | 自己的格子 `Vector2i(行, 排)`：`x` 0 左 / 1 中 / 2 右，`y` 0 前排 / 1 中排 / 2 後排 |
| `get_adjacent_allies()` | 上下左右相鄰、還活著的隊友（不含自己） |
| `get_units_in_row(row, enemy)` | 某一排還活著的角色，由左到右；`enemy` 為 `true` 查敵方 |
| `get_units_in_column(col, enemy)` | 某一行還活著的角色，由前排到後排 |
| `get_role()` | 職業名稱，例如 `"射手"` |
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
- `get_tree`、`get_node`、`get_parent`、`$節點`：請用 `get_allies()` / `get_enemies()` 和棋盤查詢
- 在射手的 `choose_target()` 裡呼叫戰鬥 API（它只負責挑目標）
- `set()`、`call()` 這類方法，或任何 `_framework` 開頭的東西
- `randi()`、`randf()`、`shuffle()` 等內建隨機：請用 `random_int()` / `random_pick()`
- `queue_free()`、`add_child()` 等新增或刪除節點的方法
- 繼承 `Boss`

戰鬥中直接寫 `enemy.hp = 0` 也不會成功，戰鬥紀錄會出現紅字。想想看為什麼要這樣設計？

## Boss

在陣型編輯器上方選想挑戰的對象。每隻 Boss 的能力寫在 `bosses/<代號>/boss.gd` 的開頭，打之前先讀一下。

Boss 也站在 3×3 棋盤上，位置寫在 `bosses/<代號>/formation.json`，預設站**前排中**，行為和戰士一樣（打你的最前排、優先同一行）。雷神的「雷擊」會打中你**所有**角色。

| `BOSS` | 名稱 |
|---|---|
| `"dummy"` | 木樁（練習用） |
| `"lv1"` | 史萊姆王 |
| `"lv2"` | 刺甲龜 |
| `"lv3"` | 雷神 |

沒有哪一種隊伍能通吃所有 Boss。打輸了就看戰鬥紀錄，調整站位、數值或技能再試一次。

## 專案結構

```
├── framework/              ← 框架，不要改
│   ├── rules.gd            ← 所有規則數值
│   ├── unit.gd             ← Unit 父類別
│   ├── roles/              ← 職業：Warrior、Tank、Archer、Mage、Healer、Assassin
│   ├── boss.gd             ← Boss 父類別
│   ├── battle.gd           ← 戰鬥流程
│   ├── formation.gd        ← 讀寫 formation.json
│   ├── validator.gd        ← 陣型、預算和作弊檢查
│   ├── editor/             ← 陣型編輯器（主場景）
│   ├── arena.tscn          ← 擂台
│   └── simulate.gd         ← 無畫面模擬
├── bosses/<代號>/          ← Boss 的 boss.gd 和站位 formation.json
└── teams/
    ├── example/            ← 範例隊伍，每種職業都有
    └── my_team/            ← 你只需要改這裡
        └── formation.json  ← 陣型（用編輯器存）
```

想多開一隊，在 `teams/` 底下新增資料夾就好，編輯器的隊伍選單會自動出現。

## 無畫面模擬

不開視窗、直接在終端機印出整場戰鬥紀錄，調數值時很方便：

```sh
godot --headless --script res://framework/simulate.gd                   # my_team 打 formation.json 記的 Boss
godot --headless --script res://framework/simulate.gd -- example        # 指定隊伍
godot --headless --script res://framework/simulate.gd -- example lv3    # 指定隊伍和 Boss
```

結束代碼：`0` 勝利、`2` 落敗、`1` 隊伍沒通過檢查。
