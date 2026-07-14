{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    pkgs.unstable.vscode
  ];

  # VS Code reads its user config from ~/Library/Application Support on macOS,
  # but from $XDG_CONFIG_HOME (~/.config) on Linux.
  home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    "Library/Application Support/Code/User/settings.json" = mkSymlink "settings.json";
    "Library/Application Support/Code/User/keybindings.json" = mkSymlink "keybindings.json";
  };

  xdg.configFile = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    "Code/User/settings.json" = mkSymlink "settings.json";
    "Code/User/keybindings.json" = mkSymlink "keybindings.json";
  };
}
