{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    restic
  ];

  xdg.configFile."restic/exclude.txt" = mkSymlink "exclude.txt";
}
