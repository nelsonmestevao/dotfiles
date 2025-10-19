{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.programs.mise;
in
{
  options.dotfiles.programs.mise = {
    enable = lib.mkEnableOption "Enable Mise configuration.";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      mise
    ];
  };
}
