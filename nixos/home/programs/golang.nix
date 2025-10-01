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
    # go_1_23
  ];

  home.file.".default-golang-pkgs" =
    config.lib.dotfiles.mkSymlink "nixos/home/programs/golang/default-golang-pkgs";
}
