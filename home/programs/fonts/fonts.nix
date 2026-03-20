{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    font-awesome
    nerd-fonts.hack
    nerd-fonts.noto
    nerd-fonts.jetbrains-mono
    noto-fonts-color-emoji
    googlesans-code
  ];
}
