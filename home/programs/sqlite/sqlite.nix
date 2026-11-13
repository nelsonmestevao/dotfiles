{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = [ pkgs.sqlite ];

  home.file.".sqliterc" = mkSymlink "sqliterc";
}
