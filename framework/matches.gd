extends RefCounted
## 擂台賽設定（講師用）：填兩邊選手的 GitHub 帳號，也就是 teams/ 底下的資料夾名稱。
## 最多 4 組會同時開打，畫面分成 2×2；點其中一場可以放大，Esc 縮回來。
## 從陣型預覽按「擂台賽」，或在 Godot 編輯器打開 framework/arena_screen.tscn 按 F6。
##
## 每組的左邊選手在下半部（藍），右邊選手在上半部（紅）；
## 先手由兩個帳號決定，左右交換結果也一樣。

const MATCHES := [
	["example", "example"],
]
