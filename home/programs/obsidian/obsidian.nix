{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    obsidian
  ];
}
