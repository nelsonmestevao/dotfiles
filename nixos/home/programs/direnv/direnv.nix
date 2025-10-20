{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    direnv
  ];

  xdg.configFile."direnv/direnvrc" = mkSymlink "direnvrc";
}
