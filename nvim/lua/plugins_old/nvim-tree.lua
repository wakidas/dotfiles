-- open File Tree when open
local function open_nvim_tree()
	require("nvim-tree.api").tree.open()
end


vim.api.nvim_create_autocmd("CursorHold", {
	pattern = "NvimTree*",
	callback = function()
		if vim.bo.filetype == "NvimTree" then
			local api = require("nvim-tree.api")
			local node = api.tree.get_node_under_cursor()

			if node and node.type ~= "directory" then
				api.node.open.preview()
			end
		end
	end,
})

vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	keys = {
		{ mode = "n", "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "NvimTreeをトグルする" },
		{
			mode = "n",
			"<C-m>",
			function()
				local current_buf = vim.api.nvim_get_current_buf()
				local filetype = vim.bo[current_buf].filetype

				if filetype == "NvimTree" then
					vim.cmd("wincmd l")              -- ファイル側へ
				else
					require("nvim-tree.api").tree.focus() -- ツリー側へ
				end
			end,
			desc = "NvimTreeとファイルのフォーカスをトグル",
		},
	},
	config = function()
		require("nvim-tree").setup({
			git = {
				enable = true,
				ignore = false, -- gitignoreされたファイルも表示
			},
			actions = {
				change_dir = {
					enable = true,
					global = false,
					restrict_above_cwd = true,
				},
			},
			update_focused_file = {
				enable = true,
				update_root = false,
				ignore_list = {},
			},
			renderer = {
				highlight_opened_files = "name", -- 開いているファイルをハイライト
				highlight_modified = "name", -- 変更されたファイルをハイライト
				highlight_git = true,        -- Gitステータスをハイライト
				icons = {
					glyphs = {
						modified = "●",
					},
				},
			},
		})
	end,
}
