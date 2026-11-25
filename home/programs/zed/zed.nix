{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    zed-editor
  ];

  # nixpkgs names Zed's command zeditor, on Linux and macOS.
  home.shellAliases.zed = "zeditor";

  xdg.configFile."zed/settings.json" = mkSymlink ./settings.json;
  xdg.configFile."zed/keymap.json" = mkSymlink ./keymap.json;
  xdg.configFile."zed/tasks.json" = mkSymlink ./tasks.json;
}
