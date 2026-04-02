local uv = vim.uv or vim.loop
local html = require("ghmd_preview.html")

local M = {
  host = "127.0.0.1",
  port = nil,
  server = nil,
  config = {
    port_start = 39087,
    port_end = 39120,
    poll_interval_ms = 500,
    refresh_mode = "save",
  },
  revisions = {},
}

local function close_client(client)
  if not client then
    return
  end
  pcall(client.read_stop, client)
  pcall(client.shutdown, client, function()
    pcall(client.close, client)
  end)
  pcall(client.close, client)
end

local function response(status, body, content_type, extra_headers)
  local reason = ({
    [200] = "OK",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [500] = "Internal Server Error",
  })[status] or "OK"
  local payload = body or ""
  local headers = {
    string.format("HTTP/1.1 %d %s", status, reason),
    "Connection: close",
    string.format("Content-Type: %s; charset=utf-8", content_type or "text/plain"),
    string.format("Content-Length: %d", #payload),
    "Cache-Control: no-store",
  }

  if extra_headers then
    for _, header in ipairs(extra_headers) do
      headers[#headers + 1] = header
    end
  end

  headers[#headers + 1] = ""
  headers[#headers + 1] = payload
  return table.concat(headers, "\r\n")
end

local function parse_request(data)
  local line = data:match("([^\r\n]+)")
  if not line then
    return nil, nil
  end
  local method, target = line:match("^(%u+)%s+([^%s]+)")
  return method, target
end

local function json_string(text)
  text = tostring(text or "")
  text = text:gsub("\\", "\\\\")
  text = text:gsub('"', '\\"')
  text = text:gsub("\b", "\\b")
  text = text:gsub("\f", "\\f")
  text = text:gsub("\n", "\\n")
  text = text:gsub("\r", "\\r")
  text = text:gsub("\t", "\\t")
  return '"' .. text .. '"'
end

local function json_encode(value)
  local kind = type(value)
  if kind == "table" then
    local is_array = true
    local max_index = 0
    for k, _ in pairs(value) do
      if type(k) ~= "number" then
        is_array = false
        break
      end
      if k > max_index then
        max_index = k
      end
    end

    local parts = {}
    if is_array then
      for i = 1, max_index do
        parts[#parts + 1] = json_encode(value[i])
      end
      return "[" .. table.concat(parts, ",") .. "]"
    end

    for k, v in pairs(value) do
      parts[#parts + 1] = json_string(k) .. ":" .. json_encode(v)
    end
    return "{" .. table.concat(parts, ",") .. "}"
  elseif kind == "string" then
    return json_string(value)
  elseif kind == "number" or kind == "boolean" then
    return tostring(value)
  elseif value == vim.NIL or value == nil then
    return "null"
  end
  return json_string(tostring(value))
end

local function buffer_name(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return "buffer-" .. tostring(buf)
  end
  return vim.fn.fnamemodify(name, ":t")
end

function M.set_config(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end
end

function M.ensure_buffer(buf)
  buf = tonumber(buf)
  if not buf then
    return
  end
  if not M.revisions[buf] then
    M.revisions[buf] = {
      rev = 0,
      saved_at = 0,
      updated_at = 0,
      name = buffer_name(buf),
    }
  else
    M.revisions[buf].name = buffer_name(buf)
  end
end

function M.touch(buf, reason)
  buf = tonumber(buf)
  if not buf then
    return
  end
  M.ensure_buffer(buf)
  local item = M.revisions[buf]
  item.updated_at = uv.hrtime()
  item.name = buffer_name(buf)
  if reason == "save" then
    item.rev = (item.rev or 0) + 1
    item.saved_at = item.updated_at
  elseif reason == "live" and (M.config.refresh_mode == "live") then
    item.rev = (item.rev or 0) + 1
  elseif item.saved_at == 0 then
    item.saved_at = item.updated_at
  end
end

function M.clear_buffer(buf)
  M.revisions[tonumber(buf)] = nil
end

function M.meta_for(buf)
  buf = tonumber(buf)
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return nil
  end
  M.ensure_buffer(buf)
  local item = M.revisions[buf]
  return {
    buf = buf,
    rev = item.rev or 0,
    refresh_mode = M.config.refresh_mode or "save",
    saved_at = item.saved_at or 0,
    updated_at = item.updated_at or 0,
    name = item.name or buffer_name(buf),
  }
end

local function handle(target)
  local path = (target or ""):match("^[^?]+") or "/"

  if path == "/" then
    return 200, "text/html", [[<html><body><p>ghmd-preview.nvim is running.</p></body></html>]]
  end

  local preview_buf = path:match("^/preview/(%d+)$")
  if preview_buf then
    M.ensure_buffer(preview_buf)
    return 200, "text/html", html.page(tonumber(preview_buf), {
      poll_interval_ms = M.config.poll_interval_ms,
      refresh_mode = M.config.refresh_mode,
      meta = M.meta_for(preview_buf),
    })
  end

  local render_buf = path:match("^/render/(%d+)$")
  if render_buf then
    M.ensure_buffer(render_buf)
    return 200, "text/html", html.render_buffer(tonumber(render_buf))
  end

  local meta_buf = path:match("^/meta/(%d+)$")
  if meta_buf then
    local meta = M.meta_for(meta_buf)
    if not meta then
      return 404, "application/json", json_encode({ error = "buffer not found" })
    end
    return 200, "application/json", json_encode(meta)
  end

  return 404, "text/plain", "not found"
end

local function start_listener(port)
  local server = uv.new_tcp()
  local ok, err = pcall(server.bind, server, M.host, port)
  if not ok then
    pcall(server.close, server)
    return nil, err
  end

  server:listen(128, function(listen_err)
    if listen_err then
      vim.schedule(function()
        vim.notify("ghmd-preview.nvim: listen error: " .. tostring(listen_err), vim.log.levels.ERROR)
      end)
      return
    end

    local client = uv.new_tcp()
    server:accept(client)
    local chunks = {}

    client:read_start(function(read_err, chunk)
      if read_err then
        close_client(client)
        return
      end
      if not chunk then
        close_client(client)
        return
      end

      chunks[#chunks + 1] = chunk
      local data = table.concat(chunks)
      if not data:find("\r\n\r\n", 1, true) then
        return
      end

      client:read_stop()
      local method, target = parse_request(data)
      if method ~= "GET" then
        client:write(response(405, "method not allowed", "text/plain"), function()
          close_client(client)
        end)
        return
      end

      vim.schedule(function()
        local ok_handle, status, content_type, body = pcall(handle, target)
        if not ok_handle then
          client:write(response(500, tostring(status), "text/plain"), function()
            close_client(client)
          end)
          return
        end

        client:write(response(status, body, content_type), function()
          close_client(client)
        end)
      end)
    end)
  end)

  return server
end

function M.ensure_started(opts)
  if opts then
    M.set_config(opts)
  end

  if M.server and M.port then
    return M.port
  end

  for port = M.config.port_start, M.config.port_end do
    local server = start_listener(port)
    if server then
      M.server = server
      M.port = port
      return port
    end
  end

  error("ghmd-preview.nvim: 空いているポートが見つかりませんでした")
end

function M.stop()
  if M.server then
    pcall(M.server.close, M.server)
  end
  M.server = nil
  M.port = nil
end

function M.url_for(buf)
  if not M.port then
    return nil
  end
  return string.format("http://%s:%d/preview/%d", M.host, M.port, buf)
end

return M
