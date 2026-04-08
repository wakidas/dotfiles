local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]

vim.keymap.set("n", "<CR>", function()
	if wininfo and wininfo.loclist == 1 then
		vim.cmd(".ll")
	else
		vim.cmd(".cc")
	end
end, {
	buffer = true,
	silent = true,
	desc = "quickfix/location list の項目を開く",
})
