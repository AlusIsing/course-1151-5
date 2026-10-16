extends RefCounted
## 你的隊伍設定。改完按 F5 就會上場。

# 要挑戰的 Boss："dummy"（木樁）、"lv1"、"lv2"、"lv3"
# 每隻 Boss 的能力寫在 bosses/ 資料夾裡的檔案開頭
const BOSS := "dummy"

# 上場名單，寫在最前面的站前排（最多 5 隻、總預算 100 點）
const MEMBERS := [
	preload("res://examples/knight.gd"),
	preload("res://examples/slime.gd"),
]
