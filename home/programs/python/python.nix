{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = [ pkgs.python314 ];

  home.file.".default-python-packages" = lib.mkIf config.dotfiles.programs.mise.enable (
    mkSymlink "default-python-packages"
  );
}
