local wezterm = require("wezterm")
local config = wezterm.config_builder()
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- GLOBAL初期化
wezterm.GLOBAL = wezterm.GLOBAL or {}

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
	saturation = 0.4, -- 彩度を下げる
	brightness = 0.3, -- 明るさを下げる
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
	local edge_foreground = background
	-- カスタムタイトルがあれば優先、なければプロセス名を表示
	local tab_title = tab.tab_title
	if not tab_title or #tab_title == 0 then
		tab_title = tab.active_pane.title
	end
	local index = tab.tab_index + 1
	local title = "   [" .. index .. "] " .. wezterm.truncate_right(tab_title, max_width - 1) .. "   "
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
  default = "#80EBDF",
  copy_mode = "#ffd700",
}

-- モード表示の設定 { 表示名, 背景色, 文字色 }
local MODE_LABELS = {
  copy_mode   = { " COPY ",   "#ffd700", "#000000" },
  resize_pane = { " RESIZE ", "#ff6b6b", "#000000" },
  activate_pane = { " PANE ",  "#6bcb77", "#000000" },
}

wezterm.on("update-right-status", function(window, pane)
  local name = window:active_key_table()

  -- モード別カーソル色切り替え
  local color = MODE_COLORS[name] or MODE_COLORS.default
  window:set_config_overrides({
    force_reverse_video_cursor = false,
    colors = {
      cursor_bg = color,
      cursor_fg = "#000000",
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
-- 定期自動保存（15分ごと）
resurrect.state_manager.periodic_save()

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
				resurrect.workspace_state.restore_workspace(state, opts)
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
