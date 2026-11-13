{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = [ pkgs.wezterm ];

  xdg.configFile."wezterm/wezterm.lua" = mkSymlink "wezterm.lua";
}
