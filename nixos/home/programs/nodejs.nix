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
    # nodejs_22
  ];

  home.file.".default-npm-packages" =
    config.lib.dotfiles.mkSymlink "nixos/home/programs/nodejs/default-npm-packages";
}
