return {
	"williamboman/mason-lspconfig.nvim",
	dependencies = {
		"williamboman/mason.nvim",
		"neovim/nvim-lspconfig",
	},
	config = function()
		-- Masonを先にセットアップ
		require("mason").setup()

		-- NOTE: styluaフォーマッターをインストールするには、Neovim内で以下を実行:
		-- :MasonInstall stylua

		-- Mason-LSPconfigのセットアップ
		require("mason-lspconfig").setup({
			ensure_installed = {
				"ruby_lsp", -- Ruby/Rails開発用
				"lua_ls", -- Neovim設定編集用
				"ts_ls", -- TypeScript/JavaScript開発用
				"pyright", -- Python開発用
			},
			automatic_installation = false,
			handlers = {
				-- デフォルトハンドラー
				function(server_name)
					local capabilities = require("cmp_nvim_lsp").default_capabilities()
					require("lspconfig")[server_name].setup({
						capabilities = capabilities,
					})
				end,

				-- ruby-lspの個別設定
				["ruby_lsp"] = function()
					local capabilities = require("cmp_nvim_lsp").default_capabilities()
					require("lspconfig").ruby_lsp.setup({
						capabilities = capabilities,
						init_options = {
							formatter = "auto",
							linters = { "rubocop" },
						},
					})
				end,

				-- lua_lsの個別設定
				["lua_ls"] = function()
					local capabilities = require("cmp_nvim_lsp").default_capabilities()
					require("lspconfig").lua_ls.setup({
						capabilities = capabilities,
						settings = {
							Lua = {
								diagnostics = {
									globals = { "vim" }, -- vimグローバル変数を認識
								},
							},
						},
					})
				end,
			},
		})

		-- キーマップ設定
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "定義へジャンプ" })
		vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "ホバー情報を表示" })
		vim.keymap.set("n", "gr", function() Snacks.picker.lsp_references() end, { desc = "参照箇所を表示" })
		vim.keymap.set("n", "gn", vim.lsp.buf.rename, { desc = "リネーム" })
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "コードアクション" })
		vim.keymap.set("n", "gi", function()
			vim.lsp.buf.implementation({ on_list = function(options)
				if #options.items == 1 then
					local item = options.items[1]
					vim.cmd("edit " .. vim.fn.fnameescape(item.filename))
					vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
				else
					vim.fn.setqflist({}, " ", options)
					vim.cmd("cfirst")
				end
			end })
		end, { desc = "実装へジャンプ" })
	end,
}
