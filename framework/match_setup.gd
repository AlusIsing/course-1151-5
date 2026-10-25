class_name MatchSetup
extends RefCounted
## 陣型編輯器 →「試打」→ 擂台 之間傳遞設定。static 變數換場景後還會保留。

static var team_name: String = Rules.DEFAULT_TEAM
static var boss_key: String = ""            # "" 代表用 formation.json 裡記的 Boss
static var formation: Formation = null      # 編輯器裡還沒存檔的陣型；null 代表直接讀檔


## 這場要用的玩家陣型
static func player_formation() -> Formation:
	if formation != null:
		return formation.copy()
	return Formation.load_dir(Rules.team_dir(team_name))


## 這場要挑戰的 Boss：編輯器選的 → formation.json 記的 → 預設
static func resolve_boss(player: Formation) -> String:
	if boss_key != "":
		return boss_key
	if player.boss_key != "":
		return player.boss_key
	return Rules.DEFAULT_BOSS
