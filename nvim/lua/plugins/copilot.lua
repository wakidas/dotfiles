return {
	"github/copilot.vim",
	event = "InsertEnter",
	cmd = { "Copilot" },
	config = function()
		vim.g.copilot_no_tab_map = true
		vim.g.copilot_assume_mapped = true
		vim.keymap.set("i", "<C-J>", function()
			return vim.fn["copilot#Accept"]("")
		end, { silent = true, expr = true, replace_keycodes = false })
	end,
}
