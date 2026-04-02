local M = {}

local function escape_html(text)
  text = tostring(text or "")
  text = text:gsub("&", "&amp;")
  text = text:gsub("<", "&lt;")
  text = text:gsub(">", "&gt;")
  text = text:gsub('"', "&quot;")
  return text
end

local function escape_attr(text)
  return escape_html(text):gsub("'", "&#39;")
end

local function trim(text)
  return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_pipe_row(line)
  local body = trim(line):gsub("^|", ""):gsub("|$", "")
  local cells = {}
  for cell in (body .. "|"):gmatch("(.-)|") do
    cells[#cells + 1] = trim(cell)
  end
  return cells
end

local function is_blank(line)
  return line == nil or trim(line) == ""
end

local function is_fence(line)
  return line and line:match("^%s*```") or line and line:match("^%s*~~~")
end

local function is_atx_heading(line)
  if not line then
    return false
  end
  local hashes = line:match("^%s*(#+)%s+")
  return hashes and #hashes <= 6
end

local function is_setext_underline(line)
  return line and (line:match("^%s*=+%s*$") or line:match("^%s*-+%s*$"))
end

local function is_hr(line)
  return line and line:match("^%s*[-*_][%s-*_][-*_]+%s*$")
end

local function is_quote(line)
  return line and line:match("^%s*>")
end

local function list_match(line)
  if not line then
    return nil
  end
  local indent, marker, rest = line:match("^(%s*)([-*+])%s+(.*)$")
  if indent then
    return #indent, false, marker, rest
  end
  indent, marker, rest = line:match("^(%s*)(%d+[.)])%s+(.*)$")
  if indent then
    return #indent, true, marker, rest
  end
  return nil
end

local function is_table_start(lines, i)
  local line = lines[i]
  local next_line = lines[i + 1]
  if not line or not next_line then
    return false
  end
  if not line:find("|", 1, true) then
    return false
  end
  -- separator line must contain only |, -, :, and whitespace, with at least one -
  if not next_line:match("^[|%-%s:]+$") or not next_line:find("-", 1, true) then
    return false
  end
  return true
end

local function render_inline(text)
  local out = {}
  local i = 1

  local function emit(raw)
    out[#out + 1] = escape_html(raw)
  end

  while i <= #text do
    local pair2 = text:sub(i, i + 1)
    local ch = text:sub(i, i)

    if pair2 == "![" then
      local close_bracket = text:find("]", i + 2, true)
      local open_paren = close_bracket and text:sub(close_bracket + 1, close_bracket + 1) == "(" and close_bracket + 1 or nil
      local close_paren = open_paren and text:find(")", open_paren + 1, true) or nil
      if close_bracket and close_paren then
        local alt = text:sub(i + 2, close_bracket - 1)
        local src = text:sub(open_paren + 1, close_paren - 1)
        out[#out + 1] = string.format(
          '<span class="md-image">🖼 <a href="%s" target="_blank" rel="noreferrer">%s</a></span>',
          escape_attr(src),
          escape_html(alt ~= "" and alt or src)
        )
        i = close_paren + 1
      else
        emit(ch)
        i = i + 1
      end
    elseif ch == "[" then
      local close_bracket = text:find("]", i + 1, true)
      local open_paren = close_bracket and text:sub(close_bracket + 1, close_bracket + 1) == "(" and close_bracket + 1 or nil
      local close_paren = open_paren and text:find(")", open_paren + 1, true) or nil
      if close_bracket and close_paren then
        local label = text:sub(i + 1, close_bracket - 1)
        local href = text:sub(open_paren + 1, close_paren - 1)
        out[#out + 1] = string.format(
          '<a href="%s" target="_blank" rel="noreferrer">%s</a>',
          escape_attr(href),
          escape_html(label)
        )
        i = close_paren + 1
      else
        emit(ch)
        i = i + 1
      end
    elseif ch == "`" then
      local close_tick = text:find("`", i + 1, true)
      if close_tick then
        local code = text:sub(i + 1, close_tick - 1)
        out[#out + 1] = string.format("<code>%s</code>", escape_html(code))
        i = close_tick + 1
      else
        emit(ch)
        i = i + 1
      end
    elseif pair2 == "**" then
      local close_bold = text:find("**", i + 2, true)
      if close_bold then
        local bold = text:sub(i + 2, close_bold - 1)
        out[#out + 1] = string.format("<strong>%s</strong>", render_inline(bold))
        i = close_bold + 2
      else
        emit(ch)
        i = i + 1
      end
    elseif pair2 == "~~" then
      local close_strike = text:find("~~", i + 2, true)
      if close_strike then
        local strike = text:sub(i + 2, close_strike - 1)
        out[#out + 1] = string.format("<del>%s</del>", render_inline(strike))
        i = close_strike + 2
      else
        emit(ch)
        i = i + 1
      end
    elseif ch == "*" then
      local close_italic = text:find("*", i + 1, true)
      if close_italic then
        local italic = text:sub(i + 1, close_italic - 1)
        out[#out + 1] = string.format("<em>%s</em>", render_inline(italic))
        i = close_italic + 1
      else
        emit(ch)
        i = i + 1
      end
    elseif ch == "_" then
      local close_italic = text:find("_", i + 1, true)
      if close_italic then
        local italic = text:sub(i + 1, close_italic - 1)
        out[#out + 1] = string.format("<em>%s</em>", render_inline(italic))
        i = close_italic + 1
      else
        emit(ch)
        i = i + 1
      end
    else
      emit(ch)
      i = i + 1
    end
  end

  return table.concat(out)
end

local render_blocks

local function render_paragraph(paragraph_lines)
  local joined = table.concat(vim.tbl_map(trim, paragraph_lines), " ")
  return "<p>" .. render_inline(joined) .. "</p>"
end

local function render_table(lines, i)
  local j = i + 2
  local rows = {}
  while lines[j] and lines[j]:find("|", 1, true) and not is_blank(lines[j]) do
    rows[#rows + 1] = split_pipe_row(lines[j])
    j = j + 1
  end

  local header = split_pipe_row(lines[i])
  local aligns = split_pipe_row(lines[i + 1])

  local parts = { "<table>", "<thead>", "<tr>" }
  for idx, cell in ipairs(header) do
    local align = aligns[idx] or ""
    local attr = ""
    if align:match("^:%-+:$") then
      attr = ' align="center"'
    elseif align:match("^:%-+$") then
      attr = ' align="left"'
    elseif align:match("^%-+:$") then
      attr = ' align="right"'
    end
    parts[#parts + 1] = string.format("<th%s>%s</th>", attr, render_inline(cell))
  end
  parts[#parts + 1] = "</tr>"
  parts[#parts + 1] = "</thead>"

  if #rows > 0 then
    parts[#parts + 1] = "<tbody>"
    for _, row in ipairs(rows) do
      parts[#parts + 1] = "<tr>"
      for idx, cell in ipairs(header) do
        local align = aligns[idx] or ""
        local attr = ""
        if align:match("^:%-+:$") then
          attr = ' align="center"'
        elseif align:match("^:%-+$") then
          attr = ' align="left"'
        elseif align:match("^%-+:$") then
          attr = ' align="right"'
        end
        parts[#parts + 1] = string.format("<td%s>%s</td>", attr, render_inline(row[idx] or ""))
      end
      parts[#parts + 1] = "</tr>"
    end
    parts[#parts + 1] = "</tbody>"
  end

  parts[#parts + 1] = "</table>"
  return table.concat(parts), j
end

local function render_list(lines, i)
  local base_indent, ordered = list_match(lines[i])
  local tag = ordered and "ol" or "ul"
  local parts = { "<" .. tag .. ">" }
  local j = i

  while lines[j] do
    local indent, is_ordered, _, rest = list_match(lines[j])
    if indent == nil or indent ~= base_indent or is_ordered ~= ordered then
      break
    end

    local task_state, task_text = rest:match("^%[([ xX])%]%s+(.*)$")
    local item_lines = { task_text or rest }
    j = j + 1

    while lines[j] do
      if is_blank(lines[j]) then
        local next_line = lines[j + 1]
        if next_line and not list_match(next_line) then
          item_lines[#item_lines + 1] = ""
          j = j + 1
        else
          break
        end
      else
        local next_indent = #(lines[j]:match("^(%s*)") or "")
        local next_list_indent, next_ordered = list_match(lines[j])
        if next_list_indent and next_list_indent == base_indent and next_ordered == ordered then
          break
        end
        if next_indent > base_indent then
          item_lines[#item_lines + 1] = lines[j]:sub(math.min(base_indent + 3, #lines[j]) + 1)
          j = j + 1
        else
          break
        end
      end
    end

    parts[#parts + 1] = "<li>"
    if task_state then
      parts[#parts + 1] = string.format(
        '<input type="checkbox" disabled %s> ',
        (task_state == "x" or task_state == "X") and "checked" or ""
      )
    end
    parts[#parts + 1] = render_blocks(item_lines)
    parts[#parts + 1] = "</li>"

    if is_blank(lines[j]) then
      j = j + 1
    end
  end

  parts[#parts + 1] = "</" .. tag .. ">"
  return table.concat(parts), j
end

local function render_blockquote(lines, i)
  local block = {}
  local j = i
  while lines[j] and is_quote(lines[j]) do
    block[#block + 1] = (lines[j]:gsub("^%s*>%s?", ""))
    j = j + 1
  end
  return "<blockquote>" .. render_blocks(block) .. "</blockquote>", j
end

local function render_fence(lines, i)
  local opener = lines[i]
  local fence = opener:match("^%s*(```+)") or opener:match("^%s*(~~~+)")
  local lang = trim((opener:match("^%s*```+%s*(.*)$") or opener:match("^%s*~~~+%s*(.*)$") or ""))
  local j = i + 1
  local block = {}
  while lines[j] do
    if lines[j]:match("^%s*" .. fence:gsub("([^%w])", "%%%1") .. "%s*$") then
      j = j + 1
      break
    end
    block[#block + 1] = lines[j]
    j = j + 1
  end
  local class_attr = lang ~= "" and string.format(' class="language-%s"', escape_attr(lang)) or ""
  local caption = lang ~= "" and string.format('<div class="code-lang">%s</div>', escape_html(lang)) or ""
  local html = string.format('%s<pre><code%s>%s</code></pre>', caption, class_attr, escape_html(table.concat(block, "\n")))
  return html, j
end

render_blocks = function(lines)
  local parts = {}
  local i = 1

  while i <= #lines do
    local line = lines[i]

    if is_blank(line) then
      i = i + 1
    elseif is_fence(line) then
      local html, next_i = render_fence(lines, i)
      parts[#parts + 1] = html
      i = next_i
    elseif is_atx_heading(line) then
      local hashes, text = line:match("^%s*(#+)%s+(.-)%s*$")
      local level = #hashes
      parts[#parts + 1] = string.format("<h%d>%s</h%d>", level, render_inline(text), level)
      i = i + 1
    elseif lines[i + 1] and is_setext_underline(lines[i + 1]) then
      local level = lines[i + 1]:match("^%s*=+%s*$") and 1 or 2
      parts[#parts + 1] = string.format("<h%d>%s</h%d>", level, render_inline(trim(line)), level)
      i = i + 2
    elseif is_hr(line) then
      parts[#parts + 1] = "<hr>"
      i = i + 1
    elseif is_quote(line) then
      local html, next_i = render_blockquote(lines, i)
      parts[#parts + 1] = html
      i = next_i
    elseif is_table_start(lines, i) then
      local html, next_i = render_table(lines, i)
      parts[#parts + 1] = html
      i = next_i
    elseif list_match(line) then
      local html, next_i = render_list(lines, i)
      parts[#parts + 1] = html
      i = next_i
    else
      local paragraph = { line }
      local j = i + 1
      while j <= #lines do
        local current = lines[j]
        if is_blank(current)
          or is_fence(current)
          or is_atx_heading(current)
          or (lines[j + 1] and is_setext_underline(lines[j + 1]))
          or is_hr(current)
          or is_quote(current)
          or is_table_start(lines, j)
          or list_match(current)
        then
          break
        end
        paragraph[#paragraph + 1] = current
        j = j + 1
      end
      parts[#parts + 1] = render_paragraph(paragraph)
      i = j
    end
  end

  return table.concat(parts, "\n")
end

local function render_empty_state(message)
  return string.format('<div class="empty-state"><p>%s</p></div>', escape_html(message))
end

function M.render_buffer(buf)
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return render_empty_state("Buffer が見つかりません。Neovim 側で開き直してください。")
  end

  local name = vim.api.nvim_buf_get_name(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local header = name ~= "" and vim.fn.fnamemodify(name, ":t") or ("buffer-" .. tostring(buf))

  if #lines == 0 then
    return string.format(
      '<div class="file-meta"><span class="file-name">%s</span></div>%s',
      escape_html(header),
      render_empty_state("このバッファは空です。")
    )
  end

  return string.format(
    '<div class="file-meta"><span class="file-name">%s</span></div>%s',
    escape_html(header),
    render_blocks(lines)
  )
end

function M.page(buf, opts)
  opts = opts or {}
  local poll_interval = tonumber(opts.poll_interval_ms) or 800
  local title = string.format("Markdown Preview · buffer %d", tonumber(buf) or 0)

  return string.format([[<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>%s</title>
  <style>
    :root {
      color-scheme: light dark;
      --bg: #ffffff;
      --canvas: #ffffff;
      --fg: #24292f;
      --muted: #57606a;
      --border: #d0d7de;
      --subtle: #f6f8fa;
      --accent: #0969da;
      --accent-hover: #0550ae;
      --blockquote: #656d76;
      --code-bg: rgba(175,184,193,0.2);
      --pre-bg: #f6f8fa;
      --shadow: 0 1px 2px rgba(31,35,40,0.04), 0 8px 24px rgba(66,74,83,0.12);
    }

    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #0d1117;
        --canvas: #0d1117;
        --fg: #c9d1d9;
        --muted: #8b949e;
        --border: #30363d;
        --subtle: #161b22;
        --accent: #58a6ff;
        --accent-hover: #79c0ff;
        --blockquote: #8b949e;
        --code-bg: rgba(110,118,129,0.4);
        --pre-bg: #161b22;
        --shadow: 0 1px 2px rgba(1,4,9,0.3), 0 8px 24px rgba(1,4,9,0.4);
      }
    }

    * { box-sizing: border-box; }
    html, body { margin: 0; padding: 0; background: var(--bg); color: var(--fg); }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji";
      line-height: 1.5;
    }
    a { color: var(--accent); text-decoration: none; }
    a:hover { color: var(--accent-hover); text-decoration: underline; }
    .page {
      min-height: 100vh;
      background: linear-gradient(180deg, var(--subtle) 0, var(--bg) 180px);
    }
    .topbar {
      position: sticky;
      top: 0;
      z-index: 10;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      padding: 14px 20px;
      border-bottom: 1px solid var(--border);
      background: color-mix(in srgb, var(--canvas) 88%%, transparent);
      backdrop-filter: blur(10px);
    }
    .topbar .meta { display: flex; flex-direction: column; gap: 2px; }
    .topbar strong { font-size: 14px; }
    .topbar span { color: var(--muted); font-size: 12px; }
    .status-pill {
      padding: 6px 10px;
      border: 1px solid var(--border);
      border-radius: 999px;
      background: var(--canvas);
      color: var(--muted);
      font-size: 12px;
    }
    .shell {
      max-width: 980px;
      margin: 28px auto;
      padding: 0 20px 40px;
    }
    .markdown-wrap {
      border: 1px solid var(--border);
      border-radius: 12px;
      background: var(--canvas);
      box-shadow: var(--shadow);
      overflow: hidden;
    }
    .markdown-body {
      padding: 32px 40px 48px;
      font-size: 16px;
      line-height: 1.7;
      word-wrap: break-word;
    }
    .file-meta {
      display: flex;
      align-items: center;
      gap: 8px;
      margin: -8px -8px 24px;
      padding: 12px 14px;
      border: 1px solid var(--border);
      border-radius: 10px;
      background: var(--subtle);
      color: var(--muted);
      font-size: 14px;
    }
    .file-name { font-weight: 600; color: var(--fg); }
    .empty-state {
      border: 1px dashed var(--border);
      border-radius: 12px;
      padding: 24px;
      color: var(--muted);
      text-align: center;
      background: var(--subtle);
    }
    .markdown-body h1,
    .markdown-body h2,
    .markdown-body h3,
    .markdown-body h4,
    .markdown-body h5,
    .markdown-body h6 {
      margin-top: 24px;
      margin-bottom: 16px;
      font-weight: 600;
      line-height: 1.25;
    }
    .markdown-body h1,
    .markdown-body h2 {
      padding-bottom: 0.3em;
      border-bottom: 1px solid var(--border);
    }
    .markdown-body h1 { font-size: 2em; }
    .markdown-body h2 { font-size: 1.5em; }
    .markdown-body h3 { font-size: 1.25em; }
    .markdown-body h4 { font-size: 1em; }
    .markdown-body h5 { font-size: 0.875em; }
    .markdown-body h6 { font-size: 0.85em; color: var(--muted); }
    .markdown-body p,
    .markdown-body ul,
    .markdown-body ol,
    .markdown-body blockquote,
    .markdown-body table,
    .markdown-body pre {
      margin-top: 0;
      margin-bottom: 16px;
    }
    .markdown-body ul,
    .markdown-body ol { padding-left: 2em; }
    .markdown-body li + li { margin-top: 0.25em; }
    .markdown-body li > p { margin-bottom: 0.5em; }
    .markdown-body input[type="checkbox"] {
      margin: 0 0.5em 0.2em -1.4em;
      vertical-align: middle;
    }
    .markdown-body blockquote {
      margin-left: 0;
      padding: 0 1em;
      color: var(--blockquote);
      border-left: 0.25em solid var(--border);
    }
    .markdown-body hr {
      height: 0.25em;
      padding: 0;
      margin: 24px 0;
      background: var(--border);
      border: 0;
    }
    .markdown-body code {
      padding: 0.18em 0.35em;
      border-radius: 6px;
      background: var(--code-bg);
      font-family: ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, monospace;
      font-size: 0.92em;
    }
    .markdown-body pre {
      position: relative;
      overflow: auto;
      padding: 16px;
      border-radius: 10px;
      background: var(--pre-bg);
      border: 1px solid var(--border);
    }
    .markdown-body pre code {
      padding: 0;
      background: transparent;
      border-radius: 0;
      display: block;
      white-space: pre;
      line-height: 1.45;
    }
    .code-lang {
      display: inline-block;
      margin-bottom: 8px;
      padding: 4px 8px;
      border-radius: 999px;
      border: 1px solid var(--border);
      background: var(--subtle);
      color: var(--muted);
      font-size: 12px;
      font-family: ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, monospace;
    }
    .markdown-body table {
      display: block;
      width: max-content;
      max-width: 100%%;
      overflow: auto;
      border-spacing: 0;
      border-collapse: collapse;
    }
    .markdown-body th,
    .markdown-body td {
      padding: 6px 13px;
      border: 1px solid var(--border);
    }
    .markdown-body th {
      font-weight: 600;
      background: var(--subtle);
    }
    .markdown-body tr:nth-child(2n) td {
      background: color-mix(in srgb, var(--subtle) 75%%, var(--canvas));
    }
    .md-image { color: var(--muted); }
    @media (max-width: 720px) {
      .shell { margin-top: 12px; padding: 0 12px 28px; }
      .topbar { padding: 12px; }
      .markdown-body { padding: 20px 16px 28px; }
    }
  </style>
</head>
<body>
  <div class="page">
    <div class="topbar">
      <div class="meta">
        <strong>Neovim Markdown Preview</strong>
        <span>GitHub っぽい見た目でライブ更新</span>
      </div>
      <div id="status" class="status-pill">connecting…</div>
    </div>
    <main class="shell">
      <section class="markdown-wrap">
        <article id="app" class="markdown-body"></article>
      </section>
    </main>
  </div>
  <script>
    const buf = %d;
    const statusNode = document.getElementById('status');
    const app = document.getElementById('app');
    const refreshMode = %s;
    let previous = '';
    let lastRev = -1;

    async function renderNow() {
      const res = await fetch('/render/' + buf + '?t=' + Date.now(), { cache: 'no-store' });
      if (!res.ok) throw new Error('HTTP ' + res.status);
      const html = await res.text();
      if (html !== previous) {
        previous = html;
        app.innerHTML = html;
      }
    }

    async function refresh() {
      try {
        const metaRes = await fetch('/meta/' + buf + '?t=' + Date.now(), { cache: 'no-store' });
        if (!metaRes.ok) throw new Error('HTTP ' + metaRes.status);
        const meta = await metaRes.json();
        if (lastRev === -1 || meta.rev !== lastRev) {
          lastRev = meta.rev;
          await renderNow();
        }
        statusNode.textContent = refreshMode === 'save' ? 'save-reload' : 'live';
      } catch (err) {
        statusNode.textContent = 'disconnected';
      }
    }
    refresh();
    setInterval(refresh, %d);
  </script>
</body>
</html>]], title, tonumber(buf) or 0, string.format('%q', opts.refresh_mode or 'save'), poll_interval)
end

return M
