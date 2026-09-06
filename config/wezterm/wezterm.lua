local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.wsl_domains = {
  { name = 'WSL:NixOS', distribution = 'NixOS', default_cwd = '~' },
}
config.default_domain = 'WSL:NixOS'

-- Windows Terminal (既定) に寄せる
config.font = wezterm.font 'Cascadia Mono'
config.font_size = 12.0
config.line_height = 1.0
config.cell_width = 1.0
config.freetype_load_target = 'Light'
config.freetype_render_target = 'HorizontalLcd'
config.bold_brightens_ansi_colors = true

config.color_scheme = 'Campbell (Windows Terminal)'
config.colors = {
  background = '#0C0C0C',
  foreground = '#CCCCCC',
  cursor_bg = '#FFFFFF',
  cursor_fg = '#000000',
  cursor_border = '#FFFFFF',
  selection_bg = '#FFFFFF',
  selection_fg = '#000000',
}

config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_background_opacity = 1.0
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.initial_cols = 120
config.initial_rows = 30
config.scrollback_lines = 9001
config.audible_bell = 'SystemBeep'

config.keys = {
  { key = 'Enter', mods = 'SHIFT', action = wezterm.action { SendString = '\x1b\r' } },
}

return config
