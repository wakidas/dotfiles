return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		lazy = false,
		config = function()
			local fs_commands = require("neo-tree.sources.filesystem.commands")

			require("neo-tree").setup({
				filesystem = {
					window = {
						mappings = {
							["<CR>"] = function(state)
								fs_commands.open(state)
							end,
						},
					},
				},
			})

			vim.api.nvim_create_autocmd("VimEnter", {
				callback = function()
					vim.cmd("Neotree filesystem reveal")
				end,
			})

			local group = vim.api.nvim_create_augroup("NeoTreeEnterToggle", { clear = true })

			vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
				group = group,
				callback = function(event)
					local ft = vim.api.nvim_get_option_value("filetype", { buf = event.buf })
					local buftype = vim.api.nvim_get_option_value("buftype", { buf = event.buf })
					if ft == "neo-tree" or buftype ~= "" then
						return
					end

					vim.keymap.set("n", "<CR>", function()
						vim.cmd("Neotree filesystem reveal")
					end, { buffer = event.buf, desc = "Neo-tree を表示" })
				end,
			})
		end,
	}
}
