{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.programs.golang;
in
{
  options.dotfiles.programs.golang = {
    enable = lib.mkEnableOption "Enable Go development environment.";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      # go_1_23
    ];

    home.file.".default-golang-pkgs" =
      config.lib.dotfiles.mkSymlink "nixos/home/programs/golang/default-golang-pkgs";
  };
}
