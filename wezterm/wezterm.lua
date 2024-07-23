--
-- ██╗    ██╗███████╗███████╗████████╗███████╗██████╗ ███╗   ███╗
-- ██║    ██║██╔════╝╚══███╔╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║
-- ██║ █╗ ██║█████╗    ███╔╝    ██║   █████╗  ██████╔╝██╔████╔██║
-- ██║███╗██║██╔══╝   ███╔╝     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║
-- ╚███╔███╔╝███████╗███████╗   ██║   ███████╗██║  ██║██║ ╚═╝ ██║
--  ╚══╝╚══╝ ╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
-- A GPU-accelerated cross-platform terminal emulator
local wezterm = require('wezterm')

local config = {}

config.window_decorations = "RESIZE"
config.window_background_opacity = 0.85
config.macos_window_background_blur = 50

config.font = wezterm.font('JetBrainsMono NF')
config.font_size = 18

config.enable_scroll_bar = false
config.enable_tab_bar = false

config.leader = {
  key = '.',
  mods = 'CTRL',
  timeout_milliseconds = 1000
}

config.keys = {
  {
    key = 's',
    mods = 'LEADER',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'v',
    mods = 'LEADER',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'p',
    mods = 'LEADER',
    action = wezterm.action.PaneSelect {
      mode = 'Activate',
    },
  },
}

return config
