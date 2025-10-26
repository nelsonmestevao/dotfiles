{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    espanso-wayland
  ];

  xdg.configFile."espanso/config" = mkSymlink "config";
  xdg.configFile."espanso/match" = mkSymlink "match";
}
