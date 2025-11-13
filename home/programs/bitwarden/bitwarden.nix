{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    bws
    bitwarden-cli
    bitwarden-desktop
  ];
}
