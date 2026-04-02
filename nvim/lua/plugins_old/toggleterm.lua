return {
	"akinsho/toggleterm.nvim",
	version = "*",
	lazy = true,
	cmd = { "ToggleTerm", "TermExec" },
	keys = {
		{ "<leader>t", desc = "Toggle terminal" },
		{ "<leader>lg", "<cmd>lua _lazygit_toggle()<CR>", desc = "Toggle lazygit" },
	},
	config = function()
		require("toggleterm").setup({
			-- size can be a number or function which is passed the current terminal
			size = 20,
			open_mapping = [[<leader>t]], -- or { [[<c-\>]], [[<c-¥>]] } if you also use a Japanese keyboard.
			hide_numbers = true, -- hide the number column in toggleterm buffers
			shade_filetypes = {},
			autochdir = false, -- when neovim changes it current directory the terminal will change it's own when next it's opened
			shade_terminals = true, -- NOTE: this option takes priority over highlights specified so if you specify Normal highlights you should set this to false
			start_in_insert = true,
			insert_mappings = false, -- whether or not the open mapping applies in insert mode
			terminal_mappings = false, -- whether or not the open mapping applies in the opened terminals
			persist_size = true,
			persist_mode = true, -- if set to true (default) the previous terminal mode will be remembered
			direction = "float",
			close_on_exit = true, -- close the terminal window when the process exits
			clear_env = false, -- use only environmental variables from `env`, passed to jobstart()
			-- Change the default shell. Can be a string or a function returning a string
			shell = vim.o.shell,
			auto_scroll = true, -- automatically scroll to the bottom on terminal output
			on_open = function(term)
				vim.cmd("startinsert!")
				vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
			end,
			-- This field is only relevant if direction is set to 'float'
			float_opts = {
				border = "curved",
				winblend = 0,
				title_pos = "center",
			},
			winbar = {
				enabled = false,
				name_formatter = function(term) --  term: Terminal
					return term.name
				end,
			},
		})
		-- ここでlazygitを開く設定を追加している
		local Terminal = require("toggleterm.terminal").Terminal
		local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })

		function _lazygit_toggle()
			lazygit:toggle()
		end

		vim.api.nvim_set_keymap("n", "<leader>lg", "<cmd>lua _lazygit_toggle()<CR>", { noremap = true, silent = true })
	end,
}
