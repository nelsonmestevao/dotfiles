{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../lib
  ];

  home.packages = with pkgs; [
    ghostty
  ];

  xdg.configFile."ghostty/config" = config.lib.dotfiles.mkSymlink "nixos/home/programs/ghostty/config";
  xdg.configFile."ghostty/themes/Day" = config.lib.dotfiles.mkSymlink "nixos/home/programs/ghostty/themes/Day";
  xdg.configFile."ghostty/themes/Night" = config.lib.dotfiles.mkSymlink "nixos/home/programs/ghostty/themes/Night";
}
