{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = [ pkgs.jujutsu ];

  xdg.configFile."jj/config.toml" = mkSymlink "config.toml";
}
