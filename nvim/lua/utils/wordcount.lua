-- 文字数カウント機能
-- Markdown/テキストファイルで文字数を表示する
-- 選択範囲がある場合は全体と選択範囲の両方を表示

local M = {}

-- 対象ファイルタイプ
local filetypes = {
	markdown = true,
	text = true,
	plaintex = true,
	tex = true,
}

function M.get()
	-- 対象ファイルタイプでない場合は空文字を返す
	if not filetypes[vim.bo.filetype] then
		return ''
	end
	local wc = vim.fn.wordcount()
	if wc.visual_chars then
		return wc.chars .. '文字 (' .. wc.visual_chars .. '選択中)'
	else
		return wc.chars .. '文字'
	end
end

return M
