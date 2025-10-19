{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    sqlite
  ];

  home.file.".sqliterc" = mkSymlink "sqliterc";
}
