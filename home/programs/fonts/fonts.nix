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
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-monochrome-emoji
    googlesans-code
  ];

  fonts.fontconfig.enable = true;
}
