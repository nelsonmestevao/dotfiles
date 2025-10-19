{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.programs.sqlite;
in
{
  options.dotfiles.programs.sqlite = {
    enable = lib.mkEnableOption "Enable SQLite configuration.";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      sqlite
    ];

    home.file.".sqliterc" = config.lib.dotfiles.mkSymlink "nixos/home/programs/sqlite/sqliterc";
  };
}
