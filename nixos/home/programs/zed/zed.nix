{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    zed-editor
  ];

  xdg.configFile."zed/settings.json" = mkSymlink "settings.json";
}
