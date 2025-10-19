{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
  ];

  home.file.".default-python-packages" =
    config.lib.dotfiles.mkSymlink "nixos/home/programs/python/default-python-packages";
}
