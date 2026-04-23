--[[
Neovim オプション設定
init.luaから抽出した基本エディタ設定
--]]

--== エディタ設定 ================================================

-- 自動リロード
vim.opt.autoread = true
vim.opt.updatetime = 1000 -- デフォルト4000msから短縮してより速い自動リロード

-- 行番号
vim.opt.number = true

-- タイムアウト設定
vim.opt.timeoutlen = 500 -- Leaderキーのタイムアウト（デフォルト: 1000ms）
vim.opt.ttimeoutlen = 0 -- モード切り替え時の遅延を無くす
vim.opt.wildoptions:append("fuzzy") -- コマンド補完で MarkdownPreview などを見つけやすくする

-- カーソル行をハイライト
vim.opt.cursorline = true

-- インデント設定
vim.opt.tabstop = 2 -- タブ文字の表示幅
vim.opt.shiftwidth = 2 -- インデント幅
vim.opt.expandtab = true -- タブをスペースに展開する
