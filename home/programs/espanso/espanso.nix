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

  xdg.configFile."espanso/config" = {
    source = ./config;
    recursive = true;
  };

  xdg.configFile."espanso/match" = {
    source = ./match;
    recursive = true;
  };
}
