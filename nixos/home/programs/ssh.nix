{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    openssh
  ];

  home.file.".ssh/config" = mkSymlink "config";
}
