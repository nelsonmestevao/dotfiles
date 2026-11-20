{
  config,
  pkgs,
  mkSymlink,
  ...
}:
let
  # VS Code reads its user config from ~/Library/Application Support on macOS,
  # but from $XDG_CONFIG_HOME (~/.config) on Linux.
  userDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Code/User"
    else
      "${config.xdg.configHome}/Code/User";
in
{
  home.packages = with pkgs; [
    pkgs.unstable.vscode
  ];

  home.file = {
    "${userDir}/settings.json" = mkSymlink ./settings.json;
    "${userDir}/keybindings.json" = mkSymlink ./keybindings.json;
    "${userDir}/tasks.json" = mkSymlink ./tasks.json;
  };
}
