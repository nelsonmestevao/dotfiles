{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    ruby_3_4
  ];

  home.file.".default-gems" = mkSymlink "default-gems";
  home.file.".irbrc" = mkSymlink "irbrc";
}
