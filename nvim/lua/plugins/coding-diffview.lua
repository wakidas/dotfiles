return {
	"sindrets/diffview.nvim",
	config = function()
		local diffview_winbar = require("utils.diffview_winbar")

		require("diffview").setup({
			hooks = {
				diff_buf_win_enter = function(_, winid)
					local label = vim.wo[winid].winbar
					local merge_names = diffview_winbar.get_merge_names()
					if label and label ~= "" then
						vim.w[winid].diffview_label = diffview_winbar.compact_label(label, merge_names)
					end

					local ok, lualine = pcall(require, "lualine")
					if ok then
						lualine.refresh({ scope = "tabpage", place = { "winbar" } })
					end
				end,
			},
		})
	end,
	lazy = false,
	keys = {
		{ mode = "n", "<leader>hh", "<cmd>DiffviewOpen HEAD~1<CR>", desc = "1つ前とのdiff" },
		{ mode = "n", "<leader>hf", "<cmd>DiffviewFileHistory %<CR>", desc = "ファイルの変更履歴" },
		{ mode = "n", "<leader>hc", "<cmd>DiffviewClose<CR>", desc = "diffの画面閉じる" },
		{ mode = "n", "<leader>hd", "<cmd>DiffviewOpen<CR>", desc = "コンフリクト解消画面表示" },
	},
}
