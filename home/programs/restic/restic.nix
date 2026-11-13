{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = [ pkgs.restic ];

  xdg.configFile."restic/exclude.txt" = mkSymlink "exclude.txt";
}
