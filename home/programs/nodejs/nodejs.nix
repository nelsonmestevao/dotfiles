{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    # nodejs_22
  ];

  home.file.".default-npm-packages" = lib.mkIf config.dotfiles.programs.mise.enable (
    mkSymlink "default-npm-packages"
  );
}
