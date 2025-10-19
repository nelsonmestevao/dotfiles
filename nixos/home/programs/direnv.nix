{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.programs.direnv;
in
{
  options.dotfiles.programs.direnv = {
    enable = lib.mkEnableOption "Enable Direnv integration.";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      direnv
    ];

    xdg.configFile."direnv/direnvrc" =
      config.lib.dotfiles.mkSymlink "nixos/home/programs/direnv/direnvrc";
  };
}
