{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    ghostty
  ];

  xdg.configFile."ghostty/config" = mkSymlink "config";
  xdg.configFile."ghostty/themes/Day" = mkSymlink "themes/Day";
  xdg.configFile."ghostty/themes/Night" = mkSymlink "themes/Night";
}
