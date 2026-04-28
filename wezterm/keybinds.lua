local wezterm = require("wezterm")
local act = wezterm.action

-- ペインの高さをタブに対するパーセンテージで設定するヘルパー関数
local function apply_pane_height_percent(window, pane, percent)
  local tab = pane:tab()
  local tab_size = tab:get_size()
  local pane_dims = pane:get_dimensions()
  local pane_id = pane:pane_id()

  local is_top_pane = false
  for _, info in ipairs(tab:panes_with_info()) do
    if info.pane:pane_id() == pane_id then
      is_top_pane = (info.top == 0)
      break
    end
  end

  local target_rows = math.floor(tab_size.rows * percent)
  local current_rows = pane_dims.viewport_rows
  local diff = current_rows - target_rows

  if is_top_pane then
    if diff > 0 then
      window:perform_action(act.AdjustPaneSize({ "Up", diff }), pane)
    elseif diff < 0 then
      window:perform_action(act.AdjustPaneSize({ "Down", -diff }), pane)
    end
  else
    if diff > 0 then
      window:perform_action(act.AdjustPaneSize({ "Down", diff }), pane)
    elseif diff < 0 then
      window:perform_action(act.AdjustPaneSize({ "Up", -diff }), pane)
    end
  end
end

local function set_pane_height_percent(percent)
  return wezterm.action_callback(function(window, pane)
    apply_pane_height_percent(window, pane, percent)
  end)
end

local function set_pane_width_percent(percent)
  return wezterm.action_callback(function(window, pane)
    local tab = pane:tab()
    local tab_size = tab:get_size()
    local pane_dims = pane:get_dimensions()
    local pane_id = pane:pane_id()

    local is_left_pane = false
    for _, info in ipairs(tab:panes_with_info()) do
      if info.pane:pane_id() == pane_id then
        is_left_pane = (info.left == 0)
        break
      end
    end

    local target_cols = math.floor(tab_size.cols * percent)
    local current_cols = pane_dims.cols
    local diff = current_cols - target_cols

    if is_left_pane then
      if diff > 0 then
        window:perform_action(act.AdjustPaneSize({ "Left", diff }), pane)
      elseif diff < 0 then
        window:perform_action(act.AdjustPaneSize({ "Right", -diff }), pane)
      end
    else
      if diff > 0 then
        window:perform_action(act.AdjustPaneSize({ "Right", diff }), pane)
      elseif diff < 0 then
        window:perform_action(act.AdjustPaneSize({ "Left", -diff }), pane)
      end
    end
  end)
end

-- ペインを分割→ズームでオーバーレイ風に起動
local function spawn_overlay_pane(command)
  return wezterm.action_callback(function(window, pane)
    local new_pane = pane:split({ direction = "Bottom", args = { "zsh", "-ic", command } })
    window:perform_action(act.TogglePaneZoomState, new_pane)
  end)
end

-- コマンドパレットにプリセットを追加
wezterm.on("augment-command-palette", function(window, pane)
  return {
    {
      brief = "Workspace: work (claude + shell)",
      icon = "md_application_brackets",
      action = wezterm.action_callback(function(window, pane)
        local cwd = pane:get_current_working_dir()
        local cwd_path = cwd and cwd.file_path or wezterm.home_dir
        -- workspaceを作成して切り替え、初期ペインでclaudeを起動
        window:perform_action(
          act.SwitchToWorkspace({
            name = "work",
            spawn = {
              cwd = cwd_path,
              args = { "zsh", "-ic", "claude" },
            },
          }),
          pane
        )
        -- workspace切り替え後に右にshellペインを追加 & privateワークスペースも作成
        wezterm.background_child_process({
          "zsh", "-ic",
          string.format(
            "sleep 0.3 && wezterm cli split-pane --right --percent 50 --cwd %q"
            .. " && PANE_ID=$(wezterm cli spawn --new-window --workspace private --cwd %q -- zsh -ic claude)"
            .. " && sleep 0.3 && wezterm cli split-pane --right --percent 50 --pane-id $PANE_ID --cwd %q",
            cwd_path, cwd_path, cwd_path
          ),
        })
      end),
    },
  }
end)

return {
  keys = {
    {
      -- workspace一覧表示（切り替え & 削除）
      key = "w",
      mods = "LEADER",
      action = wezterm.action_callback(function(win, pane)
        local current = wezterm.mux.get_active_workspace()
        local choices = {}
        for _, name in ipairs(wezterm.mux.get_workspace_names()) do
          local marker = name == current and " (current)" or ""
          table.insert(choices, {
            id = "switch:" .. name,
            label = "[switch] " .. name .. marker,
          })
        end
        for _, name in ipairs(wezterm.mux.get_workspace_names()) do
          if name ~= current then
            table.insert(choices, {
              id = "delete:" .. name,
              label = "[delete] " .. name,
            })
          end
        end
        win:perform_action(
          act.InputSelector({
            action = wezterm.action_callback(function(_, _, id, label)
              if not id then
                return
              end
              local action_type, ws_name = id:match("^(%w+):(.+)$")
              if action_type == "switch" then
                win:perform_action(act.SwitchToWorkspace({ name = ws_name }), pane)
              elseif action_type == "delete" then
                for _, mux_win in ipairs(wezterm.mux.all_windows()) do
                  if mux_win:get_workspace() == ws_name then
                    for _, tab in ipairs(mux_win:tabs()) do
                      for _, tp in ipairs(tab:panes()) do
                        wezterm.background_child_process({
                          "/opt/homebrew/bin/wezterm", "cli", "kill-pane", "--pane-id", tostring(tp:pane_id()),
                        })
                      end
                    end
                  end
                end
              end
            end),
            title = "Workspace (switch / delete)",
            choices = choices,
            fuzzy = true,
          }),
          pane
        )
      end),
    },
    {
      -- workspace新規作成
      key = "W",
      mods = "LEADER|SHIFT",
      action = act.PromptInputLine({
        description = "(wezterm) Create new workspace:",
        action = wezterm.action_callback(function(window, _, line)
          if not line then
            return
          end
          local tab = window:mux_window():active_tab()
          local p = tab and tab:active_pane()
          if not p then
            return
          end
          window:perform_action(act.SwitchToWorkspace({ name = line }), p)
        end),
      }),
    },
    {
      --workspaceの名前変更
      key = "$",
      mods = "LEADER",
      action = act.PromptInputLine({
        description = "(wezterm) Set workspace title:",
        action = wezterm.action_callback(function(win, pane, line)
          if line then
            wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
          end
        end),
      }),
    },
    {
      -- タブの名前変更
      key = ",",
      mods = "LEADER",
      action = act.PromptInputLine({
        description = "(wezterm) Set tab title:",
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            window:active_tab():set_title(line)
          end
        end),
      }),
    },
    -- コマンドパレット表示
    { key = "p", mods = "SUPER", action = act.ActivateCommandPalette },
    -- Tab移動
    { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
    { key = "Tab", mods = "SHIFT|CTRL", action = act.ActivateTabRelative(-1) },
    -- Tab入れ替え
    { key = "{", mods = "LEADER", action = act({ MoveTabRelative = -1 }) },
    -- 番号を指定してTabを移動
    {
      key = ".",
      mods = "LEADER",
      action = act.PromptInputLine({
        description = "Move tab to position (1-based):",
        action = wezterm.action_callback(function(win, pane, line)
          if not line then return end
          local target = tonumber(line)
          if target then
            win:perform_action(act.MoveTab(target - 1), pane)
          end
        end),
      }),
    },
    -- Tab新規作成
    { key = "t", mods = "SUPER", action = act({ SpawnTab = "CurrentPaneDomain" }) },
    -- Tabを閉じる
    { key = "w", mods = "SUPER", action = act({ CloseCurrentTab = { confirm = true } }) },
    { key = "}", mods = "LEADER", action = act({ MoveTabRelative = 1 }) },

    -- 画面フルスクリーン切り替え
    { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },

    -- コピーモード
    -- { key = 'X', mods = 'LEADER', action = act.ActivateKeyTable{ name = 'copy_mode', one_shot =false }, },
    { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
    -- コピー
    { key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
    -- 貼り付け
    { key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },

    -- Pane作成 leader + s or v (Vim style)
    { key = "s", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "v", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    -- Paneを閉じる leader + x
    { key = "x", mods = "LEADER", action = act({ CloseCurrentPane = { confirm = true } }) },
    -- Pane移動 leader + hlkj
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    -- Pane順回転 leader + Ctrl+h/l
    -- Ctrl+H は OS レベルで Backspace (0x08) に変換されるため Backspace で受ける
    { key = "Backspace", mods = "LEADER|CTRL", action = act.RotatePanes("CounterClockwise") },
    { key = "Backspace", mods = "LEADER", action = act.RotatePanes("CounterClockwise") },
    { key = "l", mods = "LEADER|CTRL", action = act.RotatePanes("Clockwise") },
    -- Pane選択
    { key = "[", mods = "CTRL|SHIFT", action = act.PaneSelect },
    -- 選択中のPaneのみ表示
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

    -- フォントサイズ切替
    { key = "+", mods = "SUPER", action = act.IncreaseFontSize },
    { key = "-", mods = "SUPER", action = act.DecreaseFontSize },
    -- フォントサイズのリセット
    { key = "0", mods = "SUPER", action = act.ResetFontSize },

    -- タブ切替 Cmd + 数字
    { key = "1", mods = "SUPER", action = act.ActivateTab(0) },
    { key = "2", mods = "SUPER", action = act.ActivateTab(1) },
    { key = "3", mods = "SUPER", action = act.ActivateTab(2) },
    { key = "4", mods = "SUPER", action = act.ActivateTab(3) },
    { key = "5", mods = "SUPER", action = act.ActivateTab(4) },
    { key = "6", mods = "SUPER", action = act.ActivateTab(5) },
    { key = "7", mods = "SUPER", action = act.ActivateTab(6) },
    { key = "8", mods = "SUPER", action = act.ActivateTab(7) },
    { key = "9", mods = "SUPER", action = act.ActivateTab(-1) },

    -- 検索
    { key = "f", mods = "SHIFT|CTRL", action = act.Search("CurrentSelectionOrEmptyString") },
    -- コマンドパレット
    { key = "p", mods = "SHIFT|CTRL", action = act.ActivateCommandPalette },
    -- アプリ終了
    { key = "q", mods = "SUPER", action = act.QuitApplication },
    -- 設定再読み込み
    { key = "r", mods = "SHIFT|CTRL", action = act.ReloadConfiguration },
    -- デバッグオーバーレイ
    { key = "l", mods = "SHIFT|CTRL", action = act.ShowDebugOverlay },
    -- キーテーブル用 (Paneサイズ調整)
    { key = "s", mods = "LEADER|CTRL", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
    {
      key = "a",
      mods = "LEADER",
      action = act.ActivateKeyTable({ name = "activate_pane", timeout_milliseconds = 1000 }),
    },
  },
  -- キーテーブル
  -- https://wezfurlong.org/wezterm/config/key-tables.html
  key_tables = {
    -- Paneサイズ調整 leader + s
    resize_pane = {
      { key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
      { key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
      { key = "k", action = act.AdjustPaneSize({ "Up", 3 }) },
      { key = "j", action = act.AdjustPaneSize({ "Down", 3 }) },

      -- ペインの高さをパーセンテージで設定 (1=10%, 2=20%, ..., 9=90%)
      { key = "1", action = set_pane_height_percent(0.1) },
      { key = "2", action = set_pane_height_percent(0.2) },
      { key = "3", action = set_pane_height_percent(0.3) },
      { key = "4", action = set_pane_height_percent(0.4) },
      { key = "5", action = set_pane_height_percent(0.5) },
      { key = "6", action = set_pane_height_percent(0.6) },
      { key = "7", action = set_pane_height_percent(0.7) },
      { key = "8", action = set_pane_height_percent(0.8) },
      { key = "9", action = set_pane_height_percent(0.9) },

      -- ペインの幅をパーセンテージで設定 (CTRL+1=10%, ..., CTRL+9=90%)
      { key = "1", mods = "CTRL", action = set_pane_width_percent(0.1) },
      { key = "2", mods = "CTRL", action = set_pane_width_percent(0.2) },
      { key = "3", mods = "CTRL", action = set_pane_width_percent(0.3) },
      { key = "4", mods = "CTRL", action = set_pane_width_percent(0.4) },
      { key = "5", mods = "CTRL", action = set_pane_width_percent(0.5) },
      { key = "6", mods = "CTRL", action = set_pane_width_percent(0.6) },
      { key = "7", mods = "CTRL", action = set_pane_width_percent(0.7) },
      { key = "8", mods = "CTRL", action = set_pane_width_percent(0.8) },
      { key = "9", mods = "CTRL", action = set_pane_width_percent(0.9) },

      -- Cancel the mode by pressing escape
      { key = "Escape", action = "PopKeyTable" },
      { key = "q", action = "PopKeyTable" },
      { key = "Enter", action = "PopKeyTable" },
    },
    activate_pane = {
      { key = "h", action = act.ActivatePaneDirection("Left") },
      { key = "l", action = act.ActivatePaneDirection("Right") },
      { key = "k", action = act.ActivatePaneDirection("Up") },
      { key = "j", action = act.ActivatePaneDirection("Down") },
    },
    -- copyモード leader + [
    copy_mode = {
      -- 移動
      { key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
      { key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
      { key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
      { key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
      -- 最初と最後に移動
      { key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
      { key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
      -- 左端に移動
      { key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
      { key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
      { key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
      --
      { key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
      -- 単語ごと移動
      { key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
      { key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
      { key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
      -- ジャンプ機能 t f
      { key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
      { key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
      { key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
      { key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
      -- 一番下へ
      { key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
      -- 一番上へ
      { key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
      -- viweport
      { key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
      { key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
      { key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
      -- スクロール
      { key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
      { key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
      { key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
      { key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
      -- 範囲選択モード
      { key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
      { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
      { key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
      -- コピー
      { key = "y", mods = "NONE", action = act.CopyTo("Clipboard") },

      -- コピーモードを終了
      {
        key = "Enter",
        mods = "NONE",
        action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
      },
      { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
      { key = "c", mods = "CTRL", action = act.CopyMode("Close") },
      { key = "q", mods = "NONE", action = act.CopyMode("Close") },
    },
  },
}

