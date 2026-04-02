return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = { "nvim-lua/plenary.nvim" },
	lazy = true, -- 遅延読み込みを有効化
	keys = {
		{
			"<leader>o",
			function()
				require("settings.functions.recent_files").open_project_recent()
			end,
			desc = "Recent project files",
		},
		{
			"<leader>O",
			function()
				require("telescope.builtin").find_files({ cwd = vim.fn.getcwd() })
			end,
			desc = "Telescope find files",
		},
		{ "<leader>f", "<cmd>Telescope live_grep<CR>", desc = "Telescope live grep" },
		{ "<leader>h", "<cmd>Telescope help_tags<CR>", desc = "Telescope help tags" },
	},
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			defaults = {
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--fixed-strings",
				},
			},
			pickers = {
				find_files = {
					hidden = true,
				},
			},
		})
	end,
}
