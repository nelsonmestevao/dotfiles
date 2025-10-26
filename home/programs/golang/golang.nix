{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    # go_1_23
  ];

  home.file.".default-golang-pkgs" = lib.mkIf config.dotfiles.programs.mise.enable (
    mkSymlink "default-golang-pkgs"
  );
}
