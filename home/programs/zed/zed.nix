{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = [ pkgs.zed-editor ];

  xdg.configFile."zed/settings.json" = mkSymlink "settings.json";
  xdg.configFile."zed/keymap.json" = mkSymlink "keymap.json";
  xdg.configFile."zed/tasks.json" = mkSymlink "tasks.json";
}
