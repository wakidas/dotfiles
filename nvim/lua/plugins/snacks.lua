return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  config = function(_, opts)
    require("snacks").setup(opts)
    -- picker の選択行を見やすくする（moonfly の Visual が背景と被るため）
    vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { bg = "#1a3a5c", fg = "#e0e0e0" })
    vim.api.nvim_set_hl(0, "SnacksPickerPreviewCursorLine", { bg = "#1a3a5c", fg = "#e0e0e0" })
  end,
  opts = function()
    local exclude = {}
    local exclude_file = vim.fn.getcwd() .. "/.wakida-pickerexclude"
    if vim.fn.filereadable(exclude_file) == 1 then
      for line in io.lines(exclude_file) do
        line = vim.trim(line)
        if line ~= "" and not line:match("^#") then
          table.insert(exclude, line)
        end
      end
    end

    -- recent ソース用のパス除外パターン（plain string matching）
    -- .wakida-pickerexclude のパターンをグロブ記号除去して流用
    local recent_exclude = { "node_modules" }
    for _, pat in ipairs(exclude) do
      local plain = pat:gsub("/%*+$", ""):gsub("%*+$", "")
      if plain ~= "" then
        table.insert(recent_exclude, plain)
      end
    end

    -- unique_file と除外パターンを組み合わせた transform
    local function recent_transform(item, ctx)
      ctx.meta.done = ctx.meta.done or {}
      local path = Snacks.picker.util.path(item)
      if not path or ctx.meta.done[path] then return false end
      ctx.meta.done[path] = true
      for _, pat in ipairs(recent_exclude) do
        if path:find(pat, 1, true) then return false end
      end
    end

    return {
      picker = {
        enabled = true,
        win = {
          input = {
            keys = {
              ["<C-a>"] = { "<Home>", mode = { "i", "n" }, expr = true },
              ["<C-d>"] = { "<Del>", mode = { "i" }, expr = true },
              ["<C-k>"] = { '<C-o>"_D', mode = { "i" }, expr = true },
            },
          },
        },
        sources = {
          files = { hidden = true, ignored = true, exclude = exclude, args = { "--glob", "!node_modules/**", "--follow" } },
          grep = { hidden = true, ignored = true, exclude = exclude, args = { "--glob", "!node_modules/**", "--follow" } },
          explorer = { hidden = true, ignored = true, exclude = exclude },
        },
      },
      -- インデントガイド + スコープを ┌└ で囲む GitHub 風表示（アニメなし）
      indent = { enabled = true, animate = { enabled = false }, chunk = { enabled = true } },
      -- vim.ui.input をフロートウィンドウに置き換え（rename等の入力が見やすくなる）
      input = { enabled = true },
      -- vim.notify をフロート通知に置き換え（LSP progress・エラーなどが右上に表示）
      notifier = { enabled = true, width = { min = 0.6, max = 0.8 } },
      styles = { notification = { wo = { wrap = true } } },
    }
  end,
  keys = {
    {
      "<leader>o",
      function()
        Snacks.picker.pick({
          title = "Files",
          multi = { "recent", "files" },
          format = "file",
          filter = { cwd = true },
          hidden = true,
          ignored = true,
          transform = recent_transform,
          matcher = {
            sort_empty = false,
          },
          args = { "--glob", "!node_modules/**", "--follow" },
        })
      end,
      desc = "最近のファイル",
    },
    { "<leader>f", function() Snacks.picker.grep() end, desc = "文字列検索" },
    { "<leader>h", function() Snacks.picker.help() end, desc = "ヘルプ" },
  },
}
