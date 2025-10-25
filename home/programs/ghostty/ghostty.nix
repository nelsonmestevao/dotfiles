{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    ghostty
  ];

  xdg.configFile."ghostty/config" = mkSymlink "config";
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
