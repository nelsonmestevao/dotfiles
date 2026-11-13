{
  pkgs,
  mkSymlink,
  ...
}:
{
  platforms = [ "linux" ];

  home.packages = [ pkgs.espanso-wayland ];

  xdg.configFile."espanso/config" = mkSymlink "config";
  xdg.configFile."espanso/match" = mkSymlink "match";
}
