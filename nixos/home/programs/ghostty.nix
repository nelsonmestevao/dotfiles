{
  config,
  lib,
  pkgs,
  ...
}:
let
  ghosttyFilesPath = "nixos/home/programs/ghostty";
in
{
  home.packages = with pkgs; [
    ghostty
  ];

  xdg.configFile."ghostty/config" = config.lib.dotfiles.mkSymlink "${ghosttyFilesPath}/config";
  xdg.configFile."ghostty/themes/Day" =
    config.lib.dotfiles.mkSymlink "${ghosttyFilesPath}/themes/Day";
  xdg.configFile."ghostty/themes/Night" =
    config.lib.dotfiles.mkSymlink "${ghosttyFilesPath}/themes/Night";
}
