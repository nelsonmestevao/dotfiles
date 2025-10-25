{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    ulauncher
  ];

  xdg.configFile."autostart/ulauncher.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Exec=${pkgs.ulauncher}/bin/ulauncher --hide-window
    Restart=always
    Hidden=false
    X-GNOME-Autostart-enabled=true
    Name=ULauncher
    Comment=Keyboard launcher
  '';

  xdg.configFile."ulauncher/settings.json" = mkSymlink "settings.json";
  xdg.configFile."ulauncher/extensions.json" = mkSymlink "extensions.json";
  xdg.configFile."ulauncher/shortcuts.json" = mkSymlink "shortcuts.json";

  xdg.configFile."ulauncher/user-themes" = {
    source = ./themes;
    recursive = true;
  };

  dconf.settings = lib.mkIf config.dotfiles.programs.gnome.enable {
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "ULauncher";
      command = "ulauncher-toggle";
      binding = "<Alt>Space";
    };
  };
}
