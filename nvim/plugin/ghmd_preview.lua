if vim.g.loaded_ghmd_preview then
  return
end
vim.g.loaded_ghmd_preview = true

local preview = require("ghmd_preview")
preview.setup({
  poll_interval_ms = 500,
  refresh_mode = "save",
})

vim.api.nvim_create_user_command("MarkdownPreview", function()
  preview.open()
end, {
  desc = "Open browser-based GitHub-like markdown preview",
})

vim.api.nvim_create_user_command("MarkdownPreviewBrowser", function()
  preview.open()
end, {
  desc = "Open browser-based GitHub-like markdown preview",
})

vim.api.nvim_create_user_command("MarkdownPreviewRefresh", function()
  preview.refresh()
end, {
  desc = "Refresh the current preview in your browser",
})

vim.api.nvim_create_user_command("MarkdownPreviewStop", function()
  preview.stop()
end, {
  desc = "Stop the local markdown preview server",
})

vim.api.nvim_create_user_command("MarkdownPreviewUrl", function()
  local url = preview.current_url() or preview.open()
  if url then
    vim.notify(url, vim.log.levels.INFO)
  end
end, {
  desc = "Show the current preview URL",
})
