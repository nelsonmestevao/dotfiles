{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.programs.nodejs;
in
{
  options.dotfiles.programs.nodejs = {
    enable = lib.mkEnableOption "Enable Node.js configuration.";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      # nodejs_22
    ];

    home.file.".default-npm-packages" =
      config.lib.dotfiles.mkSymlink "nixos/home/programs/nodejs/default-npm-packages";
  };
}
