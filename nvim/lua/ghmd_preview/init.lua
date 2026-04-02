local server = require("ghmd_preview.server")

local M = {}

local defaults = {
  port_start = 39087,
  port_end = 39120,
  poll_interval_ms = 500,
  auto_stop = false,
  refresh_mode = "save", -- save | live
}

local config = vim.deepcopy(defaults)
local state = {
  last_buf = nil,
  autocmds_ready = false,
  augroup = nil,
}

local function is_markdown_buffer(buf)
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return false
  end
  local ft = vim.bo[buf].filetype
  local name = vim.api.nvim_buf_get_name(buf)
  return ft == "markdown" or ft == "mdx" or name:match("%.md$") or name:match("%.markdown$") or name:match("%.mdx$")
end

local function open_url(url)
  if vim.ui and vim.ui.open then
    local ok, err = pcall(vim.ui.open, url)
    if ok then
      return true
    end
    vim.notify("ghmd-preview.nvim: vim.ui.open に失敗しました: " .. tostring(err), vim.log.levels.WARN)
  end

  local cmd
  if vim.fn.has("win32") == 1 then
    cmd = { "cmd", "/c", "start", "", url }
  elseif vim.fn.has("mac") == 1 then
    cmd = { "open", url }
  else
    cmd = { "xdg-open", url }
  end

  local ok = vim.fn.jobstart(cmd, { detach = true }) > 0
  if not ok then
    vim.notify("ghmd-preview.nvim: ブラウザを開けませんでした", vim.log.levels.ERROR)
  end
  return ok
end

local function ensure_autocmds()
  if state.autocmds_ready then
    return
  end

  state.augroup = vim.api.nvim_create_augroup("GhmdPreview", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost", "BufNewFile" }, {
    group = state.augroup,
    callback = function(args)
      if is_markdown_buffer(args.buf) then
        server.ensure_buffer(args.buf)
        server.touch(args.buf, "open")
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = state.augroup,
    callback = function(args)
      if not is_markdown_buffer(args.buf) then
        return
      end
      server.touch(args.buf, "save")
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = state.augroup,
    callback = function(args)
      if not is_markdown_buffer(args.buf) then
        return
      end
      if config.refresh_mode == "live" then
        server.touch(args.buf, "live")
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = state.augroup,
    callback = function(args)
      server.clear_buffer(args.buf)
      if state.last_buf == args.buf then
        state.last_buf = nil
      end
    end,
  })

  if config.auto_stop then
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = state.augroup,
      callback = function()
        server.stop()
      end,
    })
  end

  state.autocmds_ready = true
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  server.set_config(config)
  ensure_autocmds()
end

function M.open(buf)
  ensure_autocmds()
  buf = buf or vim.api.nvim_get_current_buf()
  if not is_markdown_buffer(buf) then
    vim.notify("ghmd-preview.nvim: markdown バッファで実行してください", vim.log.levels.WARN)
    return nil
  end

  local ok, result = pcall(server.ensure_started, config)
  if not ok then
    vim.notify(tostring(result), vim.log.levels.ERROR)
    return nil
  end

  server.ensure_buffer(buf)
  server.touch(buf, "open")
  state.last_buf = buf
  local url = server.url_for(buf)
  open_url(url)
  return url
end

function M.refresh()
  ensure_autocmds()
  if not state.last_buf or not vim.api.nvim_buf_is_valid(state.last_buf) then
    state.last_buf = vim.api.nvim_get_current_buf()
  end
  server.touch(state.last_buf, config.refresh_mode == "live" and "live" or "save")
  return M.open(state.last_buf)
end

function M.stop()
  server.stop()
  vim.notify("ghmd-preview.nvim: preview server stopped", vim.log.levels.INFO)
end

function M.current_url()
  local buf = state.last_buf or vim.api.nvim_get_current_buf()
  if not server.port then
    return nil
  end
  return server.url_for(buf)
end

return M
