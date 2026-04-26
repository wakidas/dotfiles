local wezterm = require("wezterm")
local config = wezterm.config_builder()
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- GLOBAL初期化
wezterm.GLOBAL = wezterm.GLOBAL or {}

----------------------------------------------------
-- AIエージェント完了通知 (タブ点滅 + バッジ)
----------------------------------------------------
local AGENT_USER_VAR = "claude_status"
local AGENT_DONE_VALUE = "done"
local AGENT_NOTIFY_COLOR = "#e06c75"
local AGENT_NOTIFIER_BIN = wezterm.config_dir
  .. "/wezterm-notifier.app/Contents/MacOS/terminal-notifier"
local AGENT_BADGE_SYMBOL = "◉"
local CURSOR_CYAN = "#80EBDF"

wezterm.GLOBAL.agent_alerting = wezterm.GLOBAL.agent_alerting or {}
wezterm.GLOBAL.agent_alerting_count = wezterm.GLOBAL.agent_alerting_count or 0

-- ユーザーが今このペインを実際に見ているか
-- = アクティブタブのアクティブペイン、かつ WezTerm ウィンドウに OS フォーカスがある
local function pane_is_visible_to_user(pane)
  local tab = pane:tab()
  local mux_win = pane:window()
  if not (tab and mux_win) then
    return false
  end
  local active_tab = mux_win:active_tab()
  if not active_tab or active_tab:tab_id() ~= tab:tab_id() then
    return false
  end
  local active_pane = tab:active_pane()
  if not (active_pane and active_pane:pane_id() == pane:pane_id()) then
    return false
  end
  local gui_win = wezterm.gui
    and wezterm.gui.gui_window_for_mux_window
    and wezterm.gui.gui_window_for_mux_window(mux_win:window_id())
  if not gui_win then
    return false
  end
  return gui_win.is_focused and gui_win:is_focused()
end

-- エージェントがOSC SetUserVarでclaude_status=doneを送ってきたペインを記録
wezterm.on("user-var-changed", function(_, pane, name, value)
  if name ~= AGENT_USER_VAR or value ~= AGENT_DONE_VALUE then
    return
  end
  -- ユーザーが今そのペインを実際に見ている時だけノイズなのでスキップ。
  -- WezTerm 自体が非アクティブ（別アプリ操作中）なら通知する。
  if pane_is_visible_to_user(pane) then
    return
  end
  local pid = tostring(pane:pane_id())
  if not wezterm.GLOBAL.agent_alerting[pid] then
    wezterm.GLOBAL.agent_alerting_count = wezterm.GLOBAL.agent_alerting_count + 1
    wezterm.background_child_process({
      AGENT_NOTIFIER_BIN,
      "-title", "WezTerm",
      "-message", "Agent done: " .. (pane:get_title() or ""),
      "-sound", "Glass",
      "-activate", "com.github.wez.wezterm",
      "-group", "wezterm-agent-" .. pid,
    })
  end
  wezterm.GLOBAL.agent_alerting[pid] = true
end)

local function clear_agent_alert_for_pane(pane)
  if not pane then
    return
  end
  local pid = tostring(pane:pane_id())
  if wezterm.GLOBAL.agent_alerting[pid] then
    wezterm.GLOBAL.agent_alerting[pid] = nil
    wezterm.GLOBAL.agent_alerting_count = math.max(0, wezterm.GLOBAL.agent_alerting_count - 1)
  end
end

local function tab_alert(tab)
  local marks = {}
  for _, p in ipairs(tab.panes) do
    if wezterm.GLOBAL.agent_alerting[tostring(p.pane_id)] then
      table.insert(marks, AGENT_BADGE_SYMBOL .. (p.pane_index + 1))
    end
  end
  local has_marks = #marks > 0
  return {
    has_alert = has_marks,
    color = AGENT_NOTIFY_COLOR,
    badge = has_marks and (table.concat(marks) .. " ") or "",
  }
end

config.automatically_reload_config = true
config.font_size = 12.0
-- ペイン分割時のサイズ計算を改善
config.adjust_window_size_when_changing_font_size = false
config.use_ime = true
config.macos_forward_to_ime_modifier_mask = 'SHIFT|CTRL'
config.window_background_opacity = 0.85
config.macos_window_background_blur = 20

-- ウィンドウ下部に1行分の余白を追加
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = '2cell',
}

----------------------------------------------------
-- Pane
----------------------------------------------------
-- 非アクティブなペインを暗くして、アクティブペインを分かりやすくする
config.inactive_pane_hsb = {
  brightness = 0.08, -- 明るさを下げる
}
----------------------------------------------------
-- Tab
----------------------------------------------------
-- タイトルバーを非表示
config.window_decorations = "RESIZE"
-- タブバーの表示
config.show_tabs_in_tab_bar = true
-- タブが一つでも常に表示（コピーモード等のステータス表示のため）
config.hide_tab_bar_if_only_one_tab = false
-- falseにするとタブバーの透過が効かなくなる
-- config.use_fancy_tab_bar = false

-- タブバーの透過
config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}

-- タブバーを背景色に合わせる
config.window_background_gradient = {
  colors = { "#000000" },
}

-- タブの追加ボタンを非表示
config.show_new_tab_button_in_tab_bar = false
-- nightlyのみ使用可能
-- タブの閉じるボタンを非表示
-- config.show_close_tab_button_in_tabs = false

-- タブ同士の境界線を非表示
config.colors = {
  split = CURSOR_CYAN,
  tab_bar = {
    inactive_tab_edge = "none",
  },
}

-- タブの形をカスタマイズ
-- タブの左側の装飾
local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
-- タブの右側の装飾
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = "#5c6d74"
  local foreground = "#FFFFFF"
  local edge_background = "none"
  if tab.is_active then
    background = "#ae8b2d"
    foreground = "#FFFFFF"
  end

  local alert = tab_alert(tab)
  if alert.has_alert then
    background = alert.color
    foreground = "#FFFFFF"
  end

  local edge_foreground = background
  -- カスタムタイトルがあれば優先、なければプロセス名を表示
  local tab_title = tab.tab_title
  if not tab_title or #tab_title == 0 then
    tab_title = tab.active_pane.title
  end
  local index = tab.tab_index + 1
  local title = "   " .. alert.badge .. "[" .. index .. "] " .. wezterm.truncate_right(tab_title, max_width - 1) .. "   "
  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_RIGHT_ARROW },
  }
end)

----------------------------------------------------
-- モード別カーソル色
----------------------------------------------------
local MODE_COLORS = {
  default = CURSOR_CYAN,
  copy_mode = "#ffd700",
}

-- モード表示の設定 { 表示名, 背景色, 文字色 }
local MODE_LABELS = {
  copy_mode     = { " COPY ", "#ffd700", "#000000" },
  resize_pane   = { " RESIZE ", "#ff6b6b", "#000000" },
  activate_pane = { " PANE ", "#6bcb77", "#000000" },
}

wezterm.on("update-right-status", function(window, pane)
  -- アクティブペインになったらアラート解除
  clear_agent_alert_for_pane(pane)

  -- ワークスペース名をタブバー左端に表示
  window:set_left_status(wezterm.format({
    { Background = { Color = "#3b4252" } },
    { Foreground = { Color = CURSOR_CYAN } },
    { Attribute = { Intensity = "Bold" } },
    { Text = " " .. window:active_workspace() .. " " },
  }))

  local name = window:active_key_table()

  -- アラート数の変化を tab_max_width に反映させて format-tab-title の再評価を強制する
  -- （set_right_status だけでは再評価されないため）
  local alert_count = wezterm.GLOBAL.agent_alerting_count

  -- モード別カーソル色切り替え
  local color = MODE_COLORS[name] or MODE_COLORS.default
  window:set_config_overrides({
    force_reverse_video_cursor = false,
    tab_max_width = 32 + alert_count,
    colors = {
      cursor_bg = color,
      cursor_fg = "#000000",
      split = CURSOR_CYAN,
      tab_bar = {
        inactive_tab_edge = "none",
      },
    },
  })

  -- resurrect保存メッセージ（3秒間表示）
  local status_elements = {}
  if wezterm.GLOBAL.resurrect_message_time then
    local elapsed = os.time() - wezterm.GLOBAL.resurrect_message_time
    if elapsed < 3 then
      table.insert(status_elements, { Text = wezterm.GLOBAL.resurrect_message or "" })
    else
      wezterm.GLOBAL.resurrect_message = nil
      wezterm.GLOBAL.resurrect_message_time = nil
    end
  end

  -- モード表示（背景色付き）
  local mode_info = name and MODE_LABELS[name]
  if mode_info then
    table.insert(status_elements, { Background = { Color = mode_info[2] } })
    table.insert(status_elements, { Foreground = { Color = mode_info[3] } })
    table.insert(status_elements, { Attribute = { Intensity = "Bold" } })
    table.insert(status_elements, { Text = mode_info[1] })
  end

  window:set_right_status(wezterm.format(status_elements))
end)

----------------------------------------------------
-- keybinds
----------------------------------------------------
config.disable_default_key_bindings = true
config.keys = require("keybinds").keys
config.key_tables = require("keybinds").key_tables
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

----------------------------------------------------
-- resurrect (セッション保存・復元)
----------------------------------------------------
-- 定期自動保存（30秒ごと）
resurrect.state_manager.periodic_save({ interval_seconds = 30, save_workspaces = true })

-- セッション保存 LEADER + Shift+s
table.insert(config.keys, {
  key = "S",
  mods = "LEADER|SHIFT",
  action = wezterm.action_callback(function(win, pane)
    resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
    wezterm.GLOBAL.resurrect_message = "State saved!"
    wezterm.GLOBAL.resurrect_message_time = os.time()
  end),
})

-- セッション復元 LEADER + Shift+r
table.insert(config.keys, {
  key = "R",
  mods = "LEADER|SHIFT",
  action = wezterm.action_callback(function(win, pane)
    resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
      -- idからタイプとファイル名を抽出
      local type = string.match(id, "^([^/]+)")
      id = string.match(id, "([^/]+)$")
      id = string.match(id, "(.+)%..+$")

      local opts = {
        relative = true,
        restore_text = true,
        on_pane_restore = resurrect.tab_state.default_on_pane_restore,
      }

      if type == "workspace" then
        local state = resurrect.state_manager.load_state(id, "workspace")
        local target_ws = state.workspace or id

        local current_mux_win = pane:window()
        local reuse_current = (current_mux_win:get_workspace() == target_ws)

        -- 累積防止: 復元先 workspace の既存ウィンドウを kill
        -- （同 workspace への上書き復元時のみ、現ウィンドウは再利用するため除外）
        for _, mux_win in ipairs(wezterm.mux.all_windows()) do
          if mux_win:get_workspace() == target_ws
            and not (reuse_current and mux_win:window_id() == current_mux_win:window_id()) then
            for _, mux_tab in ipairs(mux_win:tabs()) do
              for _, tp in ipairs(mux_tab:panes()) do
                wezterm.run_child_process({
                  "/opt/homebrew/bin/wezterm", "cli", "kill-pane", "--pane-id", tostring(tp:pane_id()),
                })
              end
            end
          end
        end

        -- spawn される追加ウィンドウも target_ws に属させる
        opts.spawn_in_workspace = true
        if reuse_current then
          -- 同 workspace への上書き: 現ウィンドウを window[0] として再利用、既存タブ/ペインは閉じる
          opts.window = current_mux_win
          opts.close_open_tabs = true
          opts.close_open_panes = true
        end
        resurrect.workspace_state.restore_workspace(state, opts)

        -- アクティブ workspace を target に切替（spawn or 再利用で必ず1ウィンドウ存在）
        wezterm.mux.set_active_workspace(target_ws)
      elseif type == "window" then
        local state = resurrect.state_manager.load_state(id, "window")
        resurrect.window_state.restore_window(pane:window(), state, opts)
      elseif type == "tab" then
        local state = resurrect.state_manager.load_state(id, "tab")
        resurrect.tab_state.restore_tab(pane:window(), state, opts)
      end
    end)
  end),
})

return config
