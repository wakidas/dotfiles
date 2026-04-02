return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = "nvim-tree/nvim-web-devicons",
	lazy = true,
	event = "VeryLazy",
	config = function()
		vim.opt.termguicolors = true
		require("bufferline").setup({
			options = {
				truncate_names = false,
				tab_size = 1,
				max_name_length = 50,
				name_formatter = function(buf)
					return vim.fn.fnamemodify(buf.path, ":t")
				end,
			},
		})
	end,
}
