--[[
Neovim 自動コマンド設定
init.luaから抽出した自動コマンド
--]]

--== 自動コマンド ==================================================

--[[
自動リロード設定
以下のタイミングでファイル変更を自動チェック:
- FocusGained: Neovimウィンドウにフォーカスが戻ったとき
- BufEnter: バッファに入る/切り替えるとき
- CursorHold: カーソルが'updatetime'ミリ秒アイドル状態のとき
- CursorMoved: カーソルが移動したとき
- WinEnter: ウィンドウを切り替えたとき
--]]
local checktime_grp = vim.api.nvim_create_augroup("AutoCheckTime", { clear = true })

vim.api.nvim_create_autocmd(
	{ "FocusGained", "BufEnter", "CursorHold", "CursorMoved", "WinEnter" },
	{ group = checktime_grp, pattern = "*", command = "checktime" }
)

--[[
IME自動切り替え
以下のタイミングで英語（ABC）IMEに自動切り替え:
- VimEnter: Neovim起動時
- InsertLeave: インサートモードを抜けたとき
- FocusGained: フォーカスがNeovimに戻ったとき（他のアプリから）
これによりノーマルモードで日本語入力モードが維持されるのを防ぐ

Note: CmdlineLeaveはbullets.vimのEnter処理と干渉するため除外
Note: macOSレベルのフォーカス切り替え（他アプリ→Wezterm）は
Hammerspoonで実装 → ~/.hammerspoon/init.lua
--]]
local ime_grp = vim.api.nvim_create_augroup("IMEAutoSwitch", { clear = true })
local ime = require("settings.functions.ime")

vim.api.nvim_create_autocmd({ "VimEnter", "InsertLeave", "FocusGained" }, {
	group = ime_grp,
	pattern = "*",
	callback = function()
		ime.switch_to_english_ime()
	end,
})

--[[
ターミナルIME自動切り替え
ターミナルバッファに入るときに英語（ABC）IMEに自動切り替え
ターミナルが常に英語入力で開始されることを保証
--]]
vim.api.nvim_create_autocmd({ "TermEnter", "TermOpen" }, {
	group = ime_grp,
	pattern = "*",
	callback = function()
		ime.switch_to_english_ime()
	end,
})

--[[
Markdown番号付きリストの自動再番号付け
Markdownファイルでインサートモードを抜けたときにリストを自動的に再番号付け
bullets.vimのrenumber機能を使用
--]]
local markdown_grp = vim.api.nvim_create_augroup("MarkdownAutoRenumber", { clear = true })

vim.api.nvim_create_autocmd("InsertLeave", {
	group = markdown_grp,
	pattern = { "*.md", "*.markdown" },
	callback = function()
		-- bullets.vimが利用可能でrenumberコマンドが存在するか確認
		if vim.fn.exists(":RenumberList") == 2 then
			-- 現在位置を保存
			local pos = vim.api.nvim_win_get_cursor(0)
			-- リストを再番号付け
			vim.cmd("silent! RenumberList")
			-- 位置を復元
			vim.api.nvim_win_set_cursor(0, pos)
		end
	end,
})
