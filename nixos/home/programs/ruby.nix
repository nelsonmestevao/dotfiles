{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.programs.ruby;
  rubyFilesPath = "nixos/home/programs/ruby";
in
{
  options.dotfiles.programs.ruby = {
    enable = lib.mkEnableOption "Enable Ruby development environment.";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      ruby_3_4
    ];

    home.file.".default-gems" = config.lib.dotfiles.mkSymlink "${rubyFilesPath}/default-gems";
    home.file.".irbrc" = config.lib.dotfiles.mkSymlink "${rubyFilesPath}/irbrc";
  };
}
