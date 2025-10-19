{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.programs.python;
in
{
  options.dotfiles.programs.python = {
    enable = lib.mkEnableOption "Enable Python development environment.";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
    ];

    home.file.".default-python-packages" =
      config.lib.dotfiles.mkSymlink "nixos/home/programs/python/default-python-packages";
  };
}
