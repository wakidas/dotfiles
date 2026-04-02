return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = { "markdown", "markdown_inline", "html", "tsx", "typescript", "javascript" },
			highlight = {
				enable = true,
			},
			matchup = {
				enable = true,
			},
		})
	end,
}
