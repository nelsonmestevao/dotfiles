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
    sqlite
  ];

  home.file.".sqliterc" = config.lib.dotfiles.mkSymlink "nixos/home/programs/sqlite/sqliterc";
}
