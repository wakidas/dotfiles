return {
	'nvim-lualine/lualine.nvim',
	dependencies = { 'nvim-tree/nvim-web-devicons' },
	config = function()
		local diffview_winbar = require('utils.diffview_winbar')
		local wordcount = require('utils.wordcount')

		local function short_path()
			local filepath = vim.fn.expand('%:p')
			if filepath == '' then
				return '[No Name]'
			end
			-- oil:// スキームを除去して実パスを取得
			filepath = filepath:gsub('^oil://', '')
			-- cwd からの相対パスを表示
			local cwd = vim.fn.getcwd()
			local rel = vim.fn.fnamemodify(filepath, ':.' )
			if rel == filepath then
				-- cwd外のファイルはそのまま絶対パス表示
				return filepath
			end
			local parts = vim.split(rel, '/')
			if #parts <= 1 then
				return rel
			end
			for i = 1, #parts - 1 do
				if #parts[i] > 4 then
					parts[i] = parts[i]:sub(1, 4) .. '…'
				end
			end
			return table.concat(parts, '/')
		end

		local function winbar_text()
			return diffview_winbar.resolve_label(vim.w.diffview_label, short_path())
		end

		require('lualine').setup({
			sections = {
				lualine_x = { wordcount.get, 'encoding', 'fileformat', 'filetype' },
			},
			winbar = {
				lualine_c = { winbar_text },
			},
			inactive_winbar = {
				lualine_c = { winbar_text },
			},
		})
	end,
}
