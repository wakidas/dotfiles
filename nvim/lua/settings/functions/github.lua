--[[
GitHub URL関連ユーティリティ
行番号付きのGitHub URLのコピーとブラウザで開く処理
--]]

local M = {}

-- GitHub URLを取得するヘルパー関数
local function get_github_url()
	local api = vim.api

	-- ファイルとGit情報を取得
	local filepath = api.nvim_buf_get_name(0)
	local repo_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	local rel_path = filepath:gsub(repo_root .. "/", "")
	local remote = vim.fn.systemlist("git config --get remote.origin.url")[1]
	local branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]

	-- リモートURLをHTTPS形式に変換
	remote = remote:gsub("ssh://git@github.com/", "https://github.com/")
	remote = remote:gsub("git@github.com:", "https://github.com/")
	remote = remote:gsub("%.git$", "")

	-- 行番号を取得（単一行または範囲）
	local line_part = ""
	local mode = api.nvim_get_mode().mode
	if mode == "v" or mode == "V" then
		local start_line = vim.fn.line("v")
		local end_line = vim.fn.line(".")
		if start_line > end_line then
			start_line, end_line = end_line, start_line
		end
		line_part = "#L" .. start_line .. "-L" .. end_line
	else
		local line = vim.fn.line(".")
		line_part = "#L" .. line
	end

	-- GitHub URLを構築
	return string.format("%s/blob/%s/%s%s", remote, branch, rel_path, line_part)
end

-- 通知を表示するヘルパー関数
local function show_notification(action, url)
	-- 通知用のカスタムハイライト
	vim.api.nvim_set_hl(0, "CopiedMessage", { bg = "#00ff00", fg = "#000000", bold = false })
	vim.api.nvim_set_hl(0, "CopiedMessagePath", { bg = "#00ff00", fg = "#000000", bold = true })

	vim.api.nvim_echo({
		{ action, "CopiedMessage" },
		{ url, "CopiedMessagePath" },
	}, false, {})

	-- 3秒後にメッセージをクリア
	vim.defer_fn(function()
		vim.cmd('echo ""')
	end, 3000)
end

---行番号付きのGitHub URLをクリップボードにコピー
---ノーマルモードとビジュアルモードの両方に対応
---@return nil
function M.copy_github_url()
	local url = get_github_url()
	vim.fn.setreg("+", url)
	show_notification("GitHub URLをクリップボードにコピーしました: ", url)
end

---GitHub URLをブラウザで開く
---ノーマルモードとビジュアルモードの両方に対応
---@return nil
function M.open_github_url()
	local url = get_github_url()

	-- ブラウザで開く（macOS専用）
	vim.fn.jobstart({ "open", url }, { detach = true })

	show_notification("GitHub URLをブラウザで開きました: ", url)
end

return M
