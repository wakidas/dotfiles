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
          files = { hidden = true, ignored = true, exclude = exclude, args = { "--glob", "!node_modules/**" } },
          grep = { hidden = true, ignored = true, exclude = exclude, args = { "--glob", "!node_modules/**" } },
          explorer = { hidden = true, ignored = true, exclude = exclude },
        },
      },
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
          transform = "unique_file",
          matcher = {
            sort_empty = false,
          },
          args = { "--glob", "!node_modules/**" },
        })
      end,
      desc = "最近のファイル",
    },
    { "<leader>f", function() Snacks.picker.grep() end, desc = "文字列検索" },
    { "<leader>h", function() Snacks.picker.help() end, desc = "ヘルプ" },
  },
}
