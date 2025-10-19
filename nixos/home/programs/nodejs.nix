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

  home.file.".default-npm-packages" = mkSymlink "default-npm-packages";
}
