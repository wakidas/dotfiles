return {
	"f-person/git-blame.nvim",
	-- 起動時にプラグインを読み込み
	event = "VeryLazy",
	-- keysパートがあるため、このプラグインは遅延読み込みされる
	-- キーが使用されたときにのみプラグインが読み込まれる
	-- 起動時に読み込みたい場合は、event = "VeryLazy"または
	-- lazy = falseを追加。どちらでも動作する
	opts = {
		enabled = true,
		message_template = "<sha> <author>, <date> : <summary>",
		date_format = "%Y-%m-%d",
		virtual_text_column = 1,
		highlight_group = "NonText", -- 薄いグレー
	},
}
