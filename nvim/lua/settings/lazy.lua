-- lazy.nvimをruntimepathに追加
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

-- lazy.nvimのセットアップ
require("lazy").setup({
	spec = {
		{ { import = "plugins" } },
	},
	install = { colorscheme = { "moonfly", "habamax" } },
	checker = { enabled = true, notify = false },
})
