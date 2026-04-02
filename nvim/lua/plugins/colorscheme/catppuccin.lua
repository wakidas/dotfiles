return {
	"catppuccin/nvim",
	name = "catppuccin",
	enabled = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			integrations = {
				gitsigns = true,
				nvimtree = true,
			},
		})
		vim.cmd.colorscheme("catppuccin")
	end,
}
