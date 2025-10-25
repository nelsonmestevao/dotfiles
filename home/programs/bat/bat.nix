{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    bat
  ];

  xdg.configFile."bat/config" = mkSymlink "config";
}
