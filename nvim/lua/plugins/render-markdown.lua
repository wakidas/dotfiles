return {
	"MeanderingProgrammer/render-markdown.nvim",
	cond = not vim.g.vscode,
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	ft = { "markdown" },
	opts = {
		heading = {
			enabled = true,
			sign = false,
			icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
		},
		code = {
			enabled = true,
			sign = false,
			style = "normal",
			border = "thin",
		},
		bullet = {
			enabled = true,
			icons = { "•", "◦", "▪", "▫" },
		},
		checkbox = {
			enabled = true,
			unchecked = { icon = "[ ] " },
			checked = { icon = "[x] " },
		},
		quote = {
			enabled = true,
			icon = "│",
		},
		dash = {
			enabled = true,
			icon = "─",
		},
		link = {
			enabled = true,
			image = "",
			hyperlink = "",
		},
	},
}
