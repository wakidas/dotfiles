--[[
ファイルパス関連ユーティリティ
ファイルパスをクリップボードにコピーする処理
--]]

local M = {}

---ファイルの絶対パスをクリップボードにコピー
function M.copy_full_path()
	local abs_path = vim.fn.expand("%:p")
	-- URIスキーム（oil://, fugitive://, term://等）を除去
	abs_path = abs_path:gsub("^%w+://", "")
	vim.fn.setreg("+", abs_path)
	vim.notify("コピーしました: " .. abs_path, vim.log.levels.INFO)
end

---ファイルのcwd相対パス:行数をクリップボードにコピー
function M.copy_path_with_line()
	local rel_path = vim.fn.expand("%:.")
	rel_path = rel_path:gsub("^%w+://", "")
	local path_with_line = rel_path .. ":" .. vim.fn.line(".")
	vim.fn.setreg("+", path_with_line)
	vim.notify("コピーしました: " .. path_with_line, vim.log.levels.INFO)
end

return M
