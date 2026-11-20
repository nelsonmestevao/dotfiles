{
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # Linux only: macOS gets it from the Homebrew cask. Unstable for 1.4.
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.unstable.ghostty ];

  xdg.configFile."ghostty/config" = mkSymlink ./config;
  xdg.configFile."ghostty/keybindings" =
    if pkgs.stdenv.hostPlatform.isDarwin then mkSymlink ./macos else mkSymlink ./linux;

  xdg.configFile."ghostty/themes/Day" = mkSymlink ./themes/Day;
  xdg.configFile."ghostty/themes/Night" = mkSymlink ./themes/Night;

  # Only does something where GNOME is on.
  dotfiles.programs.gnome.shortcuts.terminal = {
    name = "Terminal";
    command = "ghostty";
    binding = "<Super>Return";
  };
}
