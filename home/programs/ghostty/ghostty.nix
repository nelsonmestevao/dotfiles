{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # Linux only: macOS gets it from the Homebrew cask. Unstable for 1.4.
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.unstable.ghostty ];

  xdg.configFile."ghostty/config" = mkSymlink "config";
  xdg.configFile."ghostty/keybindings" = mkSymlink (
    if pkgs.stdenv.hostPlatform.isDarwin then "macos" else "linux"
  );

  xdg.configFile."ghostty/themes/Day" = mkSymlink "themes/Day";
  xdg.configFile."ghostty/themes/Night" = mkSymlink "themes/Night";

  dconf.settings = lib.mkIf config.dotfiles.programs.gnome.enable {
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Terminal";
      command = "ghostty";
      binding = "<Super>Return";
    };
  };
}
