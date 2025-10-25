{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    jetbrains.datagrip
  ];

  home.file.".ideavimrc" = mkSymlink "ideavimrc";
}
