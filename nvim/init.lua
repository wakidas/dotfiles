--[[
Neovim設定
lazy.nvimパッケージマネージャーを使用した個人設定
--]]

-- グローバル変数を読み込み
require("settings.globals")

-- プラグインマネージャーを読み込み
require("settings.lazy")

-- エディタオプションを読み込み
require("settings.options")

-- 自動コマンドを読み込み
require("settings.autocmds")

-- キーマップ設定を読み込み
require("settings.keymaps")

-- ローカル設定ファイル許可
vim.o.exrc = true
vim.o.secure = true -- チーム開発ならtrueを推奨

vim.o.updatetime = 200
