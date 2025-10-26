{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
  ];

  home.file.".default-python-packages" = lib.mkIf config.dotfiles.programs.mise.enable (
    mkSymlink "default-python-packages"
  );
}
