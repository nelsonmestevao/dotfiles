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

local function get_color_scheme_by(appearance)
  if appearance:find "Dark" then
    return "Google Dark (base16)"
  else
    return "Google Light (base16)"
  end
end

config.color_scheme = get_color_scheme_by(wezterm.gui.get_appearance())

config.font = wezterm.font('JetBrainsMono NF')
config.font_size = 18

config.enable_scroll_bar = false
config.enable_tab_bar = false

config.leader = {
  -- https://github.com/wez/wezterm/issues/4055#issuecomment-2137129562
  key = ' ',
  mods = 'CTRL',
  timeout_milliseconds = 1000
}

config.keys = {
  {
    key = 'v',
    mods = 'LEADER',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'h',
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
