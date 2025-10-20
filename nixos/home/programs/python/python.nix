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

  home.file.".default-python-packages" = mkSymlink "default-python-packages";
}
