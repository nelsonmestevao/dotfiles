{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    playerctl
    pulseaudio
  ];

  # ── Services ──────────────────────────────────────────────────────────
  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };
    settings = {
      theme = {
        light = {
          name = "vicinae-light";
          icon_theme = "default";
        };
        dark = {
          name = "vicinae-dark";
          icon_theme = "default";
        };
      };
      keybinding = "emacs";
      keybinds = {
        toggle-action-panel = "control+L";
      };
      launcher_window = {
        opacity = 0.98;
      };
      favorites = [
        "applications:slack"
        "applications:spotify"
        "applications:zen"
        "@vicinae/clipboard:history"
      ];
    };
  };

  # ── GNOME / dconf Integration ────────────────────────────────────────
  dotfiles.programs.gnome.extensions.vicinae.enable = true;

  dconf.settings = lib.mkIf config.dotfiles.programs.gnome.enable {
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Vicinae";
      command = "vicinae toggle";
      binding = "<Alt>Space";
    };
  };
}
