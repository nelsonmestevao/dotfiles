{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = [ pkgs.direnv ];

  xdg.configFile."direnv/direnvrc" = mkSymlink "direnvrc";
}
