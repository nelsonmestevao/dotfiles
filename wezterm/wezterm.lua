local wezterm = require('wezterm')

local config = wezterm.config_builder()

config.window_decorations = "RESIZE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 50

config.font = wezterm.font('JetBrainsMono NF')
config.font_size = 18

config.enable_scroll_bar = false
config.enable_tab_bar = false

return config
