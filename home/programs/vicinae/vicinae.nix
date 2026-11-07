{
  config,
  lib,
  pkgs,
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
    # Upstream leaves this null and picks a package itself; name ours (see
    # config/overlays.nix) so CI can find it.
    package = pkgs.vicinae;
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
        "clipboard:history"
      ];
    };
  };

  # ── GNOME / dconf Integration ────────────────────────────────────────
  dotfiles.programs.gnome.extensions.vicinae.enable = config.dotfiles.programs.gnome.enable;

  dconf.settings = lib.mkIf config.dotfiles.programs.gnome.enable {
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Vicinae";
      command = "vicinae toggle";
      binding = "<Alt>Space";
    };
  };
}
