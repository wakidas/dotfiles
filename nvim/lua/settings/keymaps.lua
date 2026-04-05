--[[
Neovim キーマップ設定
init.luaから抽出したすべてのキーマップ設定
--]]

--== 基本キーマップ ==================================================

-- 手動リロード
vim.keymap.set("n", "<leader>r", ":checktime<CR>", { desc = "ファイルが変更されていたらリロード" })

-- 完全な設定リロード（Luaキャッシュクリア + init.lua再読み込み + lazy.nvimプラグインリロード）
vim.keymap.set("n", "<leader>R", function()
	-- 1. ~/.config/nvim/lua配下のすべてのLuaモジュールキャッシュをクリア
	for name, _ in pairs(package.loaded) do
		if name:match("^settings") or name:match("^plugins") then
			package.loaded[name] = nil
		end
	end

	-- 2. init.luaを再読み込み
	dofile(vim.fn.stdpath("config") .. "/init.lua")

	-- 3. lazy.nvimプラグインをリロード
	require("lazy").sync()

	vim.notify("設定を完全にリロードしました！", vim.log.levels.INFO)
end, { desc = "設定を完全にリロード" })

-- 最近のファイルを:browse oldfilesで開く
vim.keymap.set("n", "<leader>fo", "<cmd>browse oldfiles<CR>", { desc = "最近のファイル" })

-- バッファ移動
vim.keymap.set("n", "<Tab>", "<cmd>bnext<CR>", { desc = "次のバッファ" })
vim.keymap.set("n", "<S-Tab>", "<cmd>bprev<CR>", { desc = "前のバッファ" })

-- バッファを削除して前のバッファに切り替え
vim.keymap.set("n", "<leader>w", "<cmd>bprev<bar>bdelete! #<CR>", { desc = "バッファを削除して前のバッファへ" })

-- Emacs風カーソル移動
vim.keymap.set("n", "<C-a>", "<Home>")
vim.keymap.set("n", "<C-e>", "<End>")
vim.keymap.set("n", "<C-k>", '"_C<Esc>')

-- x, s, cでヤンクしない
vim.keymap.set("n", "x", '"_x')
vim.keymap.set("n", "s", '"_s')
vim.keymap.set("n", "c", '"_c')
vim.keymap.set("v", "x", '"_x')
vim.keymap.set("v", "s", '"_s')
vim.keymap.set("v", "c", '"_c')

-- クイックエスケープ
vim.keymap.set("i", "jj", "<ESC>", { silent = true })

-- インサートモードのEmacs風キーバインド
vim.keymap.set("i", "<C-d>", "<Del>")
vim.keymap.set("i", "<C-a>", "<Home>")
vim.keymap.set("i", "<C-e>", "<End>")
vim.keymap.set("i", "<C-f>", "<Right>")
vim.keymap.set("i", "<C-b>", "<Left>")
vim.keymap.set("i", "<C-k>", '<C-o>"_C')
vim.keymap.set("i", "<Down>", "<C-o>gj")
vim.keymap.set("i", "<Up>", "<C-o>gk")

-- コマンドラインのEmacs風キーバインド
vim.keymap.set("c", "<C-p>", "<Up>")
vim.keymap.set("c", "<C-n>", "<Down>")
vim.keymap.set("c", "<C-b>", "<Left>")
vim.keymap.set("c", "<C-f>", "<Right>")
vim.keymap.set("c", "<C-a>", "<Home>")
vim.keymap.set("c", "<C-e>", "<End>")

--== 外部モジュールの読み込み ======================================

-- ユーティリティモジュールのインポート
local filepath = require("settings.functions.filepath")
local github = require("settings.functions.github")
local buffer = require("settings.functions.buffer")
local diary = require("settings.functions.diary")

--== カスタム関数 ===============================================

-- ファイルパスキーマップ
vim.keymap.set("n", "<leader>c", filepath.copy_full_path, { desc = "ファイルのフルパスをクリップボードにコピー" })
vim.keymap.set("n", "<leader>C", filepath.copy_path_with_line, { desc = "ファイルパス:行数をクリップボードにコピー" })

-- GitHub連携キーマップ
vim.keymap.set({ "n", "v" }, "<leader>gh", github.copy_github_url, { desc = "GitHub URLをクリップボードにコピー" })
vim.keymap.set({ "n", "v" }, "<leader>gho", github.open_github_url, { desc = "GitHub URLをブラウザで開く" })

-- バッファ管理キーマップ
vim.keymap.set("n", "<leader>bo", buffer.delete_other_buffers, { desc = "現在のバッファ以外をすべて削除" })

-- 日記キーマップ
vim.keymap.set("n", "<leader>dd", diary.open_today_diary, { desc = "今日の日記を開く" })

-- インサートモードでスペースが正常に動作することを保証
vim.keymap.set("i", "<Space>", "<Space>", { noremap = true, nowait = true })

-- ターミナルモードのエスケープマッピング（Esc2回）
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-N>", { desc = "Esc2回でターミナルモードを抜ける" })

-- ヤンクしたらクリップボードにコピー
vim.opt.clipboard = "unnamedplus"

-- Ctrl-wを強制的に単語削除として設定
vim.cmd([[inoremap <C-w> <C-\><C-o>dB]])

--== ターミナル ======================================================

-- nvim内蔵ターミナルを下部に分割して開く
vim.keymap.set("n", "<leader>tt", function()
	vim.cmd("botright split | terminal")
	vim.cmd("startinsert")
end, { desc = "下部にターミナルを分割して開く" })

--== Claude Code ====================================================

-- nvim内蔵ターミナルでclaude codeを起動（終了後もシェルが残る）
vim.keymap.set("n", "<leader>cc", function()
	local claude_cmd = vim.fn.shellescape(vim.env.HOME .. "/.local/bin/claude; exec zsh")
	vim.cmd("botright split | terminal zsh -c " .. claude_cmd)
	vim.cmd("startinsert")
end, { desc = "ターミナルでClaude Codeを開く" })
