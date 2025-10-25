{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    jujutsu
  ];

  xdg.configFile."jj/config.toml" = mkSymlink "config.toml";
}
