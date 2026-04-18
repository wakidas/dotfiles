--[[
ファイルパス関連ユーティリティ
ファイルパスをクリップボードにコピーする処理
--]]

local M = {}

---git project rootからの相対パスを取得（取得できない場合は絶対パスを返す）
local function get_git_relative_path()
	local abs_path = vim.fn.expand("%:p")
	abs_path = abs_path:gsub("^%w+://", "")
	local git_root = vim.fn.system("git -C " .. vim.fn.shellescape(vim.fn.fnamemodify(abs_path, ":h")) .. " rev-parse --show-toplevel 2>/dev/null")
	git_root = vim.trim(git_root)
	if git_root == "" then
		return abs_path
	end
	-- git_root末尾のスラッシュを正規化し、相対パスを計算
	local rel_path = abs_path:sub(#git_root + 2)
	return rel_path
end

---ファイルのgit root相対パスをクリップボードにコピー
function M.copy_full_path()
	local path = get_git_relative_path()
	vim.fn.setreg("+", path)
	vim.notify("コピーしました: " .. path, vim.log.levels.INFO)
end

---ファイルのgit root相対パス:行数をクリップボードにコピー（visual modeでは範囲形式 L100-105）
function M.copy_path_with_line()
	local path = get_git_relative_path()
	local mode = vim.api.nvim_get_mode().mode
	local line_part
	if mode == "v" or mode == "V" or mode == "\22" then
		local start_line = vim.fn.line("v")
		local end_line = vim.fn.line(".")
		if start_line > end_line then
			start_line, end_line = end_line, start_line
		end
		if start_line == end_line then
			line_part = tostring(start_line)
		else
			line_part = "L" .. start_line .. "-" .. end_line
		end
	else
		line_part = tostring(vim.fn.line("."))
	end
	local path_with_line = path .. ":" .. line_part
	vim.fn.setreg("+", path_with_line)
	vim.notify("コピーしました: " .. path_with_line, vim.log.levels.INFO)
end

return M
