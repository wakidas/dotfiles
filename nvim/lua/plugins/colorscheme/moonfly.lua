return {
	"bluz71/vim-moonfly-colors",
	name = "moonfly",
	priority = 1000,
	config = function()
		vim.cmd.colorscheme("moonfly")
		vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2a2a3a" })
		vim.api.nvim_set_hl(0, "CursorColumn", { bg = "#2a2a3a" })
	end,
}
