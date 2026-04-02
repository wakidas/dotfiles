--[[
バッファ関連ユーティリティ
バッファ管理操作を処理
--]]

local M = {}

---現在のバッファ以外をすべて削除
---@return nil
function M.delete_other_buffers()
	local current_buf = vim.api.nvim_get_current_buf()
	local buffers = vim.api.nvim_list_bufs()
	local deleted_count = 0

	for _, buf in ipairs(buffers) do
		-- 現在のバッファと無効/非リストバッファをスキップ
		if buf ~= current_buf and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
			vim.api.nvim_buf_delete(buf, { force = true })
			deleted_count = deleted_count + 1
		end
	end

	vim.notify(deleted_count .. "個のバッファを削除しました", vim.log.levels.INFO)
end

return M
