return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		-- 設定をここに記述
		-- 空のままにするとデフォルト設定を使用
		-- 詳細は下記の設定セクションを参照
	},
	keys = {
		{
			"?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "バッファローカルのキーマップ表示",
		},
	},
}
