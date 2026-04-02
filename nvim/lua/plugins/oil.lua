return {
	{
		"stevearc/oil.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		lazy = false,
		config = function()
			require("oil").setup({
				-- ファイルアイコンを表示
				default_file_explorer = true,
				-- カラムの設定
				columns = {
					"icon",
				},
				-- バッファオプション
				buf_options = {
					buflisted = false,
					bufhidden = "hide",
				},
				-- ウィンドウオプション
				win_options = {
					wrap = false,
					signcolumn = "no",
					cursorcolumn = false,
					foldcolumn = "0",
					spell = false,
					list = false,
					conceallevel = 3,
					concealcursor = "nvic",
				},
				-- 削除時にゴミ箱へ
				delete_to_trash = true,
				-- 隠しファイルをスキップ
				skip_confirm_for_simple_edits = true,
				-- プロンプトで保存確認
				prompt_save_on_select_new_entry = true,
				-- プレビューウィンドウの動作設定
				preview_win = {
					-- カーソル移動時にプレビューを自動更新
					update_on_cursor_moved = true,
					-- プレビュー方法: "fast_scratch"で高速表示
					preview_method = "fast_scratch",
				},
				-- キーマップ
				keymaps = {
					["g?"] = "actions.show_help",
					["<CR>"] = "actions.select",
					["<C-v>"] = "actions.select_vsplit",
					["<C-s>"] = "actions.select_split",
					["<C-t>"] = "actions.select_tab",
					["gp"] = "actions.preview",
					["<C-c>"] = "actions.close",
					["<C-r>"] = "actions.refresh",
					["-"] = "actions.parent",
					["_"] = "actions.open_cwd",
					["`"] = "actions.cd",
					["~"] = "actions.tcd",
					["gs"] = "actions.change_sort",
					["gx"] = "actions.open_external",
					["g."] = "actions.toggle_hidden",
					["g\\"] = "actions.toggle_trash",
				},
				-- floatウィンドウの設定
				float = {
					padding = 2,
					max_width = 0,
					max_height = 0,
					border = "rounded",
					win_options = {
						winblend = 0,
					},
					-- プレビューの分割方向（右にプレビュー）
					preview_split = "right",
				},
				-- プレビューウィンドウの設定
				preview = {
					max_width = 0.9,
					min_width = { 40, 0.4 },
					width = nil,
					max_height = 0.9,
					min_height = { 5, 0.1 },
					height = nil,
					border = "rounded",
					win_options = {
						winblend = 0,
					},
				},
				-- ファイルの表示順
				view_options = {
					show_hidden = true,
					is_hidden_file = function(name, _)
						return vim.startswith(name, ".")
					end,
					is_always_hidden = function(name, _)
						return name == ".." or name == ".git"
					end,
					sort = {
						{ "type", "asc" },
						{ "name", "asc" },
					},
				},
			})

			-- 通常バッファで `-` を押すとoilを開く
			vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "親ディレクトリを開く" })

			-- Enterで現在のファイルのディレクトリをoilで開く
			vim.keymap.set("n", "<CR>", function()
				require("oil").open()
			end, { desc = "Oilファイルエクスプローラを開く" })

			-- フロートウィンドウでプレビュー付きで開く
			vim.keymap.set("n", "<leader>p", function()
				require("oil").open_float(nil, { preview = {} })
			end, { desc = "Oilをプレビュー付きフロートで開く" })
		end,
	},
}
