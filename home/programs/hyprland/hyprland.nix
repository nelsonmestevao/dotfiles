{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.xwayland.enable = true;

  home.packages = with pkgs; [
    hyprcursor
    hypridle
    hypridle
    hyprlock
    hyprpaper
    hyprpicker
    hyprshot
    hyprsunset
    pyprland
    waybar
  ];

  xdg.configFile."hypr/hyprland.conf" = mkSymlink "hyprland.conf";
}
