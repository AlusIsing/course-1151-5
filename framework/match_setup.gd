class_name MatchSetup
extends RefCounted
## 場景之間傳遞設定。static 變數換場景後還會保留。

static var mode: String = "versus"                 # "boss"：試打 Boss；"versus"：擂台賽（讀 matches.gd）
static var team: String = Rules.DEFAULT_TEAM       # 預覽、試打的隊伍（GitHub 帳號）
static var boss_key: String = Rules.DEFAULT_BOSS
