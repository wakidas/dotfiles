return {
	"tpope/vim-rails",
	ft = { "ruby", "eruby", "haml", "slim" }, -- Ruby関連ファイルでのみ読み込み
	config = function()
		-- vim-railsの基本的なキーマップ
		-- gf: カーソル下のファイルを開く（Rails規約に基づく）
		-- :A: 関連ファイル（テスト⇔実装）へ移動
		-- :R: 関連ファイルへ移動（より柔軟）
		-- :Emodel, :Econtroller, :Eview: 各種ファイルへ移動

		-- 追加のカスタムキーマップ（お好みで）
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "ruby", "eruby" },
			callback = function()
				vim.keymap.set("n", "<leader>a", ":A<CR>", { buffer = true, desc = "関連ファイルへ移動" })
				vim.keymap.set("n", "<leader>r", ":R<CR>", { buffer = true, desc = "関連ファイルへ移動（柔軟）" })
			end,
		})
	end,
}
