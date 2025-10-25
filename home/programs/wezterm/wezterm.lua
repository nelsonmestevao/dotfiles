--
-- ██╗    ██╗███████╗███████╗████████╗███████╗██████╗ ███╗   ███╗
-- ██║    ██║██╔════╝╚══███╔╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║
-- ██║ █╗ ██║█████╗    ███╔╝    ██║   █████╗  ██████╔╝██╔████╔██║
-- ██║███╗██║██╔══╝   ███╔╝     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║
-- ╚███╔███╔╝███████╗███████╗   ██║   ███████╗██║  ██║██║ ╚═╝ ██║
--  ╚══╝╚══╝ ╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
-- A GPU-accelerated cross-platform terminal emulator
local wezterm = require('wezterm')

local config = wezterm.config_builder()

config.window_decorations = "NONE" -- "RESIZE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 30
config.win32_system_backdrop = "Acrylic"

local function get_color_scheme_by(appearance)
  if appearance:find "Light" then
    return "Google Light (base16)"
  else
    return "Google Dark (base16)"
  end
end

config.color_scheme = get_color_scheme_by(wezterm.gui.get_appearance())

config.font = wezterm.font('JetBrainsMono NF')
config.font_size = 18

config.enable_scroll_bar = false

config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.show_tabs_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = false
config.tab_bar_at_bottom = true

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
  {
    key = 'l',
    mods = 'META',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'h',
    mods = 'META',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'k',
    mods = 'META',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'j',
    mods = 'META',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
}

for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'META',
    action = wezterm.action.ActivateTab(i - 1),
  })
end

return config
