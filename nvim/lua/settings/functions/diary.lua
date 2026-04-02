--[[
日記ユーティリティ関数
Obsidian vault内の今日の日記ファイルを開くまたは作成
--]]

local M = {}

-- 日記ディレクトリのパス（環境変数 OBSIDIAN_DIARY_DIR の設定が必要）
local diary_dir = vim.env.OBSIDIAN_DIARY_DIR

-- 今日の日記ファイルパスを取得
function M.get_today_diary_path()
  local today = os.date("%Y-%m-%d")
  return diary_dir .. "/" .. today .. ".md"
end

-- 今日の日記ファイルを開いてタイムスタンプエントリを追加
function M.open_today_diary()
  if not diary_dir then
    vim.notify("環境変数 OBSIDIAN_DIARY_DIR を設定してください", vim.log.levels.ERROR)
    return
  end
  local filepath = M.get_today_diary_path()
  local file_exists = vim.fn.filereadable(filepath) == 1

  -- ディレクトリが存在しない場合は作成
  vim.fn.mkdir(diary_dir, "p")

  -- ファイルを開く
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))

  if file_exists then
    -- ファイルが存在する場合：末尾に移動してタイムスタンプを追加
    vim.cmd("normal! G")
    local timestamp = os.date("%H:%M")
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- ファイルが空でなく最後の行が空でない場合は空行を追加
    if #lines > 0 and lines[#lines] ~= "" then
      vim.api.nvim_buf_set_lines(0, -1, -1, false, { "", "## " .. timestamp, "" })
    else
      vim.api.nvim_buf_set_lines(0, -1, -1, false, { "## " .. timestamp, "" })
    end
    vim.cmd("normal! G")
  else
    -- 新規ファイル：タイトルとタイムスタンプを追加
    local today = os.date("%Y-%m-%d")
    local timestamp = os.date("%H:%M")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "# " .. today,
      "",
      "## " .. timestamp,
      "",
    })
    vim.cmd("normal! G")
  end

  -- インサートモードに入る
  vim.cmd("startinsert")
end

return M
