{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.hm.gvariant) mkTuple mkUint32;

  # Sets the keys of `<action>-1` to `<action>-<count>`: `keys n` for number n.
  numbered =
    action: count: keys:
    lib.genAttrs' (lib.range 1 count) (n: lib.nameValuePair "${action}-${toString n}" (keys n));

  # Workspaces 1 to 9 are on the number keys 1 to 9, and workspace 10 is on 0.
  workspaceKey = n: toString (lib.mod n 10);
in
{
  platforms = [ "linux" ];

  # These two are not settings. Each enabled extension adds itself to them
  # (see mkGnomeExtensionModule), and this module reads them below. User
  # files leave them alone, hence `internal`.
  options.enabledExtensions = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    internal = true;
    description = "UUIDs of the enabled GNOME extensions.";
  };

  options.extensionSchemaDirs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    internal = true;
    description = "GSettings schema folders of the enabled GNOME extensions.";
  };

  home.packages = with pkgs; [
    wmctrl
    gnome-tweaks
    wl-clipboard
    adwaita-icon-theme
  ];

  home.sessionVariables.GSETTINGS_SCHEMA_DIR = lib.concatStringsSep ":" config.dotfiles.programs.gnome.extensionSchemaDirs;

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = config.dotfiles.programs.gnome.enabledExtensions;
      favorite-apps = [ ];
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-automatic = true;
      night-light-temperature = mkUint32 2700;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      control-center = [ "<Super>i" ];
      home = [ "<Super>e" ];
      screensaver = [ "<Super>Escape" ];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };

    "org/gnome/settings-daemon/plugins/power" = {
      power-button-action = "interactive";
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = false;
      workspaces-only-on-primary = true;
      center-new-windows = true;
    };

    "org/gnome/desktop/interface" = {
      clock-format = "24h";
      clock-show-seconds = false;
      clock-show-weekday = true;
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      gtk-enable-primary-paste = false;
      gtk-key-theme = "Default";
      gtk-theme = "Adwaita";
      icon-theme = "Adwaita";
      cursor-theme = "Adwaita";
      show-battery-percentage = true;
      toolkit-accessibility = false;
    };

    "org/gnome/desktop/media-handling" = {
      autorun-never = false;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "close,minimize,maximize:appmenu";
      num-workspaces = 10;
      focus-mode = "sloppy";
    };

    "org/gnome/shell/keybindings" = numbered "switch-to-application" 10 (_: [ ]) // {
      toggle-overview = [ ];
      toggle-application-view = [ "<Super>a" ];
      toggle-message-tray = [ "<Super>m" ];
      toggle-quick-settings = [ "<Super>s" ];
      show-screen-ui = [ "Print" ];
      show-screen-recording-ui = [ "<Control>Print" ];
      screenshot = [ "<Super>Print" ];
      screenshot-window = [ "<Alt>Print" ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      switch-input-source = [ "<Super>Space" ];
      switch-input-source-backward = [ "<Shift><Super>Space" ];
      close = [ "<Super>q" ];
      move-to-monitor-down = [ ];
      move-to-monitor-left = [ ];
      move-to-monitor-right = [ ];
      move-to-monitor-up = [ ];
      move-to-workspace-down = [ ];
      move-to-workspace-up = [ ];
      switch-to-workspace-down = [ ];
      switch-to-workspace-left = [ ];
      switch-to-workspace-right = [ ];
      switch-to-workspace-up = [ ];
      activate-window-menu = [ ];
      panel-main-menu = [ ];
      panel-run-dialog = [ ];
      raise = [ ];
      raise-or-lower = [ ];
      lower = [ ];
      maximize = [ ];
      maximize-horizontally = [ ];
      maximize-vertically = [ ];
      minimize = [ ];
      set-spew-mark = [ ];
      show-desktop = [ ];
      switch-windows = [ ];
      switch-windows-backward = [ ];
      switch-to-workspace-11 = [ ];
      switch-to-workspace-12 = [ ];
      toggle-above = [ ];
      toggle-fullscreen = [ ];
      toggle-on-all-workspaces = [ ];
      toggle-maximized = [ "<Super>f" ];
      unmaximize = [ ];
    }
    // numbered "move-to-workspace" 10 (n: [ "<Super><Shift>${workspaceKey n}" ])
    // numbered "switch-to-workspace" 10 (n: [ "<Super>${workspaceKey n}" ]);

    "org/gnome/mutter/wayland/keybindings" = {
      restore-shortcuts = [ ];
    }
    // numbered "switch-to-session" 12 (n: [ "<Primary><Alt>F${toString n}" ]);

    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${config.home.homeDirectory}/Pictures/Wallpapers/lockscreen.jpg";
      picture-uri-dark = "file://${config.home.homeDirectory}/Pictures/Wallpapers/lockscreen.jpg";
    };

    "org/gnome/desktop/background" = {
      picture-uri = "file://${config.home.homeDirectory}/Pictures/Wallpapers/desktop.jpg";
      picture-uri-dark = "file://${config.home.homeDirectory}/Pictures/Wallpapers/desktop.jpg";
    };

    "org/gnome/desktop/input-sources" = {
      sources = [
        (mkTuple [
          "xkb"
          "pt"
        ])
        (mkTuple [
          "xkb"
          "us"
        ])
      ];
      xkb-options = [ "caps:ctrl_modifier" ];
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "default";
      natural-scroll = false;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      send-events = "enabled";
      natural-scroll = true;
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
      disable-while-typing = true;
    };
  };
}
