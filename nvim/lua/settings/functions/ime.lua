--[[
IME（入力メソッドエディタ）ユーティリティ
macOS用の英語IME自動切り替え処理
--]]

local M = {}

---英語IMEに切り替え（macOS専用）
---im-selectを使用してABCキーボードレイアウトに切り替え
---@return nil
function M.switch_to_english_ime()
	vim.fn.jobstart("im-select com.apple.keylayout.ABC", { detach = true })
end

return M
