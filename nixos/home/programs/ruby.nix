{
  config,
  lib,
  pkgs,
  ...
}:
let
  rubyFilesPath = "nixos/home/programs/ruby";
in
{
  home.packages = with pkgs; [
    ruby_3_4
  ];

  home.file.".default-gems" = config.lib.dotfiles.mkSymlink "${rubyFilesPath}/default-gems";
  home.file.".irbrc" = config.lib.dotfiles.mkSymlink "${rubyFilesPath}/irbrc";
}
