# 集合！Vibe 出你的自走棋物件大隊

用 Godot 4 做的迷你自走棋。你要用**物件**組出一支隊伍，先打倒 Boss 練功，最後發 PR 把隊伍合併進專案，和全班在擂台上對戰。

一路上你會用到物件導向的幾個核心概念：

| 概念 | 在這個專案裡長什麼樣子 |
|---|---|
| 物件 | 每隻角色、整支隊伍都是一個物件 |
| 繼承 | 角色 `extends Archer`、`extends Tank`，隊伍 `extends Team` |
| 覆寫 | 覆寫 `on_hurt()`、`on_death()` 這些事件，做出角色的技能 |
| 多型 | 同一場戰鬥裡，每隻角色對同一個事件的反應都不一樣 |
| 封裝 | 不能直接改 `hp`，只能透過 `deal_damage()`、`heal()` |
| 幀與 delta | 用 `on_frame(delta)` 做動畫，邏輯和畫面分開 |

## 快速開始

1. 安裝 **Godot 4.7**
2. 用 Godot 打開這個資料夾（選 `project.godot`）
3. 按 **F5** 打開**陣型預覽**，隊伍選 `example`、挑戰選 `dummy`，按「試打」

### 建立自己的隊伍

1. 複製 `teams/example/` 整個資料夾，改名成**你的 GitHub 帳號**，例如 `teams/zyzy0826/`
2. 打開裡面的 `team.gd`，把 `github` 改成你的帳號、`team_name` 改成你的隊名
3. 回到陣型預覽，隊伍選單就會出現你的隊伍

你寫的所有東西（角色、技能、自己的父類別）都放在這個資料夾裡。

### 陣型預覽

- 左邊列出隊伍成員，右邊的 3×3 棋盤顯示每隻角色站在哪一格
- 右上角顯示用掉的預算，下面列出所有沒通過檢查的地方
- 改完程式**切回遊戲視窗就會自動更新**，也可以按「重新讀取」
- 通過檢查之後才能按「試打」

### 擂台

上半部是 Boss 的棋盤、下半部是你的棋盤，兩邊的前排面對面。右邊是**戰鬥紀錄**，每一次攻擊、技能、倒下都會寫在這裡，名字前面會標格子，例如「[前排左] 騎士 攻擊 [前排中] 木樁」。角色沒照你想的動，先來這裡找原因。

| 按鍵 | 功能 |
|---|---|
| R | 重新開始 |
| Esc | 回陣型預覽 |
| 空白鍵 | 暫停 / 繼續 |
| 1 / 2 / 3 | 1 倍 / 2 倍 / 4 倍速 |

## 三個階段

| 階段 | 你要做的事 | 建議挑戰 |
|---|---|---|
| 1. 宣告物件 | 選職業、設定數值和站位，把角色放進 `team.gd` | 木樁、史萊姆王 |
| 2. 寫基礎技能 | 覆寫事件，用 `heal()`、`deal_damage()` 這些 API 做技能 | 刺甲龜、雷神 |
| 3. 和 AI 一起寫技能 | 自己設計技能類別、共用的父類別，組出最強的隊伍 | 擂台賽 |

每個階段都可以隨時換隊員、改站位。

### 階段 1：宣告物件

一隻角色就是一個 `.gd` 檔。選一個職業 `extends`，在 `_init()` 裡設定數值和站位：

```gdscript
extends Archer
## 弓手：站在後排中間，可以打任何一格

func _init() -> void:
	unit_name = "弓手"
	max_hp = 10
	attack = 4
	color = Color("#ffcc80")
	grid_position = Vector2i(1, 2)   # 中間那一行、後排
```

再把它加進 `team.gd` 的 `members`：

```gdscript
extends Team

func _init() -> void:
	team_name = "火鍋隊"
	github = "zyzy0826"            # 要和資料夾名稱一樣
	members = [
		preload("knight.gd"),
		preload("archer.gd"),     # 同一個資料夾的檔案，直接寫檔名
	]
```

`grid_position = Vector2i(行, 排)`：

|  | 行 0（左） | 行 1（中） | 行 2（右） |
|---|---|---|---|
| **排 0（前排）** | `(0, 0)` | `(1, 0)` | `(2, 0)` |
| **排 1（中排）** | `(0, 1)` | `(1, 1)` | `(2, 1)` |
| **排 2（後排）** | `(0, 2)` | `(1, 2)` | `(2, 2)` |

前排面對敵人。每隻角色要站不同格，同一個角色檔只能上場一次。想要兩個弓手，就再寫一個檔案繼承第一個，只改站位：

```gdscript
extends "archer.gd"

func _init() -> void:
	super()                          # 先用 archer.gd 的設定
	grid_position = Vector2i(0, 2)   # 再改站位
```

### 階段 2：寫基礎技能

覆寫事件，在裡面呼叫戰鬥 API：

```gdscript
extends Unit
## 小護士：受傷時，幫相鄰的隊友各回 1 血

func _init() -> void:
	unit_name = "小護士"
	max_hp = 16
	attack = 3
	color = Color("#ff9ecf")
	grid_position = Vector2i(1, 1)

func on_hurt(amount: int, source: Unit) -> void:
	for ally in get_adjacent_allies():
		heal(ally, 1)
```

可以用的事件、API 和查詢都列在下面的 [角色 API](#角色-api)。

### 階段 3：和 AI 一起寫技能

可以在自己的資料夾裡新增任何類別，用 `preload` 引用：

```gdscript
# teams/zyzy0826/skills/fireball.gd
extends RefCounted
## 火球：對目標造成傷害

var power: int = 2

func cast(caster: Unit, target: Unit) -> void:
	caster.deal_damage(target, power)
```

```gdscript
# teams/zyzy0826/mage.gd
extends Mage
const Fireball = preload("skills/fireball.gd")

var fireball = Fireball.new()

func on_attack(target: Unit) -> void:
	fireball.cast(self, target)
```

也可以讓好幾隻角色繼承自己寫的父類別：`extends "my_base.gd"`。這時子類別的 `_init()` **第一行要寫 `super()`**，不然父類別 `_init()` 裡設定的數值不會生效。

技能還是只能透過戰鬥 API 生效，數值上限和[不能做的事](#不能做的事)也都一樣。請 AI 幫忙時，記得把這份 README 給它看。

## 戰鬥規則

- 雙方各有 **3×3 棋盤**：前排、中排、後排，每排有左、中、右三格。角色站好就**不會移動**
- 每回合每隻角色輪流行動一次，**順序固定**：我方先、Boss 隊伍後；同一隊從前排到後排、每排從左到右。輪到時已經倒下的角色不會行動
- 一回合結束時結算倒下的角色；一方全滅就結束；**超過 30 回合**還沒打倒 Boss 算你輸，同歸於盡也算你輸
- 隨機用固定種子，同樣的隊伍打同樣的 Boss，結果永遠一樣

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

技能不花點數，但戰鬥 API 有數值上限（見下方）。超過預算或違規的隊伍不能上場，陣型預覽會列出原因。

## 角色 API

### 事件（覆寫這些來做技能）

| 方法 | 什麼時候觸發 |
|---|---|
| `on_battle_start()` | 戰鬥開始時 |
| `on_attack(target)` | 自己攻擊之後 |
| `on_hurt(amount, source)` | 自己受傷之後 |
| `on_death()` | 自己倒下時 |
| `on_ally_death(ally)` | 有隊友倒下時 |
| `on_frame(delta)` | 每一幀，**只能做畫面效果** |

觸發順序和行動順序一樣。血量歸零的角色只會再觸發 `on_death`。

### 戰鬥 API

| 方法 | 效果 | 上限 |
|---|---|---|
| `deal_damage(target, amount)` | 造成傷害 | 每次 1–5 |
| `heal(target, amount)` | 回血 | 每次 1–5，不超過 `max_hp` |
| `buff_attack(target, amount)` | 加攻擊 | 每次 1–3，最多加到 15 |
| `summon_token(hp, attack)` | 召喚沒有技能的分身到自己的位置（第二隻起放在附近的空格） | 只能在 `on_death` 用，合計 `hp + 2×attack ≤ 10` |
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
| `get_grid_position()` | 自己的格子 `Vector2i(行, 排)` |
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

擂台賽會在講師的電腦上執行全班的程式，所以上場前會掃描你資料夾裡**每一個** `.gd` 檔，出現下面這些就不能上場：

- 用到自己資料夾以外的檔案（`preload`、`extends "路徑"` 都只能指向自己的資料夾）
- `class_name`：全班的類別名稱會撞在一起，自己寫的類別請用 `preload("檔名.gd")`
- `@tool`
- 系統、檔案、網路、引擎的功能：`OS`、`FileAccess`、`DirAccess`、`load()`、`Engine`、`ProjectSettings`、`Input`、各種 `Server`、`Thread`、`HTTPRequest` 等
- `_process`、`_ready`、`_input` 這類引擎方法：動畫請改用 `on_frame(delta)`
- 在 `on_frame` 裡呼叫戰鬥 API
- 在射手的 `choose_target()` 裡呼叫戰鬥 API（它只負責挑目標）
- `get_tree`、`get_node`、`get_parent`、`$節點`：請用 `get_allies()` / `get_enemies()` 和棋盤查詢
- `set()`、`call()` 這類方法，或任何 `_framework` 開頭的東西
- `randi()`、`randf()`、`shuffle()` 等內建隨機：請用 `random_int()` / `random_pick()`
- `queue_free()`、`add_child()` 等新增或刪除節點的方法
- 在 `_init()` 以外改 `hp`、`max_hp`、`attack`、`grid_position`（包括 `enemy.hp = 0`）：戰鬥中請用 `deal_damage()`、`heal()`、`buff_attack()`
- 三個引號的多行字串
- 繼承 `Boss`

就算繞過掃描，戰鬥中直接改 `hp` 也不會成功，戰鬥紀錄會出現紅字。想想看為什麼要這樣設計？

## Boss

在陣型預覽上方選想挑戰的對象。每隻 Boss 的能力寫在 `bosses/<代號>/boss.gd` 的開頭，打之前先讀一下。

Boss 也站在 3×3 棋盤上，預設站**前排中**，行為和戰士一樣（打你的最前排、優先同一行）。雷神的「雷擊」會打中你**所有**角色。

| 代號 | 名稱 |
|---|---|
| `dummy` | 木樁（練習用） |
| `lv1` | 史萊姆王 |
| `lv2` | 刺甲龜 |
| `lv3` | 雷神 |

打輸了就看戰鬥紀錄，調整站位、數值或技能再試一次。

## 擂台賽

### 交隊伍

1. Fork 這個專案，在 `teams/<你的 GitHub 帳號>/` 寫好隊伍（資料夾名稱要和帳號一模一樣，包含大小寫）
2. 在自己電腦上跑檢查，全部 ✅ 再發 PR：

   ```sh
   godot --headless --script res://tools/validate.gd -- 你的GitHub帳號
   ```

3. 發 PR，**只改自己的資料夾**

發 PR 後 GitHub Actions 會自動跑同一套檢查（第一次發 PR 要等講師按「Approve and run」）。結果在 PR 的 **Checks** 分頁，點進「檢查學員隊伍」看 Summary，沒通過的地方會寫出檔案、行號和修法：

| 檢查 | 內容 |
|---|---|
| 1. 只修改自己的資料夾 | PR 改到 `teams/<你的帳號>/` 以外的檔案就失敗 |
| 2. 程式碼掃描 | [不能做的事](#不能做的事)；沒通過的話後面都不會執行 |
| 3. 語法 | 每個 `.gd` 都要能編譯 |
| 4. 隊伍設定 | `team.gd`、站位、數值範圍、預算 |
| 5. 試打 Boss Lv1 | 戰鬥要能跑完、技能執行時不能出錯；**輸贏不影響** |

技能裡有無窮迴圈的話，檢查會在 10 分鐘後被中止。

### 對戰規則

- 兩隊交錯行動：先手 1 號 → 後手 1 號 → 先手 2 號 → 後手 2 號 …（號碼照各隊的行動順序），一隊沒人了另一隊就繼續
- 先手由兩隊的 GitHub 帳號決定，同一組對戰每次都是同一隊先手
- 雙方同時全滅，**後手獲勝**
- 超過 30 回合還沒分出勝負，比**剩餘血量比例**（還活著的角色血量總和 ÷ 開場時的 max_hp 總和），一樣多也是後手獲勝

### 開打（講師）

在 `framework/matches.gd` 填入對戰組合，最多 4 組同時開打：

```gdscript
const MATCHES := [
	["帳號A", "帳號B"],
	["帳號C", "帳號D"],
]
```

在陣型預覽按「擂台賽」開始。多組時畫面分成 2×2，點其中一場可以放大，Esc 縮回來。

## 無畫面模擬

不開視窗、直接在終端機印出整場戰鬥紀錄：

```sh
godot --headless --script res://framework/simulate.gd                     # example 打木樁
godot --headless --script res://framework/simulate.gd -- 帳號 lv3         # 指定隊伍和 Boss
godot --headless --script res://framework/simulate.gd -- 帳號A vs 帳號B   # 隊伍對戰
```

- 打 Boss 的結束代碼：`0` 勝利、`2` 落敗、`1` 隊伍沒通過檢查
- 隊伍對戰的最後一行是 JSON，可以給賽程工具讀：

  ```json
  {"left": "帳號A", "right": "帳號B", "first": "帳號A", "winner": "帳號B", "rounds": 12, "reason": "帳號A 全滅"}
  ```

  一隊沒通過檢查時，另一隊不戰而勝；兩隊都沒通過時 `winner` 是空字串，結束代碼為 `1`

## 專案結構

```
├── framework/                ← 框架，不要改
│   ├── rules.gd              ← 所有規則數值
│   ├── unit.gd               ← Unit 父類別
│   ├── roles/                ← 職業：Warrior、Tank、Archer、Mage、Healer、Assassin
│   ├── team.gd               ← Team 父類別
│   ├── boss.gd               ← Boss 父類別
│   ├── battle.gd             ← 戰鬥流程
│   ├── validator.gd          ← 程式碼掃描、站位和預算檢查
│   ├── preview/              ← 陣型預覽（主場景）
│   ├── arena_screen.tscn     ← 擂台畫面（一場或 2×2 四場）
│   ├── arena.tscn            ← 單場擂台
│   ├── matches.gd            ← 擂台賽對戰組合（講師用）
│   └── simulate.gd           ← 無畫面模擬
├── tools/validate.gd         ← 隊伍檢查（本機和 GitHub Actions 共用）
├── .github/workflows/        ← PR 自動檢查
├── bosses/<代號>/boss.gd     ← Boss
└── teams/
    ├── example/              ← 範例隊伍，每種職業都有
    └── <你的 GitHub 帳號>/   ← 你只需要改這裡
        └── team.gd           ← 隊名、帳號、成員
```
