{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = [ pkgs.jetbrains.datagrip ];

  home.file.".ideavimrc" = mkSymlink "ideavimrc";
}
