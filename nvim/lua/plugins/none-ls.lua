return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"williamboman/mason.nvim",
	},
	lazy = true,
	event = "LspAttach",
	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {
				-- Lua formatter
				null_ls.builtins.formatting.stylua.with({
					extra_args = function()
						-- .stylua.tomlがあればそれを使用、なければデフォルト設定
						local config_file = vim.fn.findfile(".stylua.toml", ".;")
						if config_file ~= "" then
							return { "--config-path", config_file }
						end
						return {
							"--indent-type",
							"Tabs",
							"--indent-width",
							"2",
							"--quote-style",
							"AutoPreferDouble",
						}
					end,
				}),
			},
			-- フォーマット時の設定
			on_attach = function(client, bufnr)
				-- LSPのフォーマット機能を有効化
				if client.supports_method("textDocument/formatting") then
					-- 既存の<leader>fキーマップがLSPフォーマットを使用するので、追加設定は不要

					-- オプション: 保存時の自動フォーマット
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({ bufnr = bufnr })
						end,
					})
				end
			end,
		})
	end,
}
