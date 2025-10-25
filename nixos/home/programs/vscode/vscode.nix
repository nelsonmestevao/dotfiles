{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    vscode
  ];

  xdg.configFile."Code/User/settings.json" = mkSymlink "settings.json";
  xdg.configFile."Code/User/keybindings.json" = mkSymlink "keybindings.json";
}
