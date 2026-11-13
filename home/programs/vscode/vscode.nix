{
  lib,
  pkgs,
  mkSymlink,
  ...
}:
let
  # VS Code reads its user config from ~/Library/Application Support on macOS,
  # but from $XDG_CONFIG_HOME (~/.config) on Linux.
  userFiles =
    folder:
    lib.genAttrs' [ "settings.json" "keybindings.json" "tasks.json" ] (
      file: lib.nameValuePair "${folder}/${file}" (mkSymlink file)
    );
in
{
  home.packages = with pkgs; [
    pkgs.unstable.vscode
  ];

  home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    userFiles "Library/Application Support/Code/User"
  );
  xdg.configFile = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (userFiles "Code/User");
}
