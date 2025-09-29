{
  config,
  lib,
  pkgs,
  ...
}:
with lib.hm.gvariant;
let
  gnomeExtensions = with pkgs.gnomeExtensions; [
    auto-move-windows
    blur-my-shell
    caffeine
    color-picker
    pop-shell
    space-bar
    top-bar-organizer
    vitals
    wake-on-lan
    wiggle
    # freon
    # system-monitor
  ];
  extensionsFilesPath = "nixos/home/programs/gnome/extensions";
in
{
  home.packages = with pkgs; [
    wmctrl
    gnome-tweaks
    ulauncher
    # albert
    # walker
    wl-clipboard
    adwaita-icon-theme
  ] ++ gnomeExtensions;

  # dconf write /org/gnome/desktop/input-sources/xkb-options "['caps:ctrl_modifier']"
  # dconf write '/org/gnome/shell/extensions/pop-shell/toggle-floating' "['<Meta><Shift>Space']"
  # gsettings get org.gnome.desktop.interface color-scheme
  # gsettings set org.gnome.desktop.background picture-uri-dark file:///home/nelson/Pictures/desktop.jpg
  # gsettings set org.gnome.desktop.background picture-uri file:///home/nelson/Pictures/login.jpg

  xdg.configFile."pop-shell/config.json" = config.lib.dotfiles.mkSymlink "${extensionsFilesPath}/pop-shell/config.json";

  # xdg.configFile."autostart/albert.desktop".text = ''
  #   [Desktop Entry]
  #   Type=Application
  #   Exec=${pkgs.albert}/bin/albert
  #   Hidden=false
  #   X-GNOME-Autostart-enabled=true
  #   Name=Albert
  #   Comment=Keyboard launcher
  # '';

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

  services.copyq.enable = true;

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = map (extension: extension.extensionUuid) gnomeExtensions;
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
    };

    "org/gnome/settings-daemon/plugins/power" = {
      worspaces-only-on-primary = true;
      power-button-action = "interactive";
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = false;
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

    "org/gnome/shell/keybindings" = {
      switch-to-application-1 = [ ];
      switch-to-application-2 = [ ];
      switch-to-application-3 = [ ];
      switch-to-application-4 = [ ];
      switch-to-application-5 = [ ];
      switch-to-application-6 = [ ];
      switch-to-application-7 = [ ];
      switch-to-application-8 = [ ];
      switch-to-application-9 = [ ];
      switch-to-application-10 = [ ];
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
      move-to-workspace-1 = [ "<Super><Shift>1" ];
      move-to-workspace-2 = [ "<Super><Shift>2" ];
      move-to-workspace-3 = [ "<Super><Shift>3" ];
      move-to-workspace-4 = [ "<Super><Shift>4" ];
      move-to-workspace-5 = [ "<Super><Shift>5" ];
      move-to-workspace-6 = [ "<Super><Shift>6" ];
      move-to-workspace-7 = [ "<Super><Shift>7" ];
      move-to-workspace-8 = [ "<Super><Shift>8" ];
      move-to-workspace-9 = [ "<Super><Shift>9" ];
      move-to-workspace-10 = [ "<Super><Shift>0" ];
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      switch-to-workspace-5 = [ "<Super>5" ];
      switch-to-workspace-6 = [ "<Super>6" ];
      switch-to-workspace-7 = [ "<Super>7" ];
      switch-to-workspace-8 = [ "<Super>8" ];
      switch-to-workspace-9 = [ "<Super>9" ];
      switch-to-workspace-10 = [ "<Super>0" ];
      switch-to-workspace-11 = [ ];
      switch-to-workspace-12 = [ ];
      toggle-above = [ ];
      toggle-fullscreen = [ ];
      toggle-on-all-workspaces = [ ];
      toggle-maximized = [ "<Super>f" ];
      unmaximize = [ ];
    };

    "org/gnome/mutter/wayland/keybindings" = {
      restore-shortcuts = [ ];
      switch-to-session-1 = [ "<Primary><Alt>F1" ];
      switch-to-session-2 = [ "<Primary><Alt>F2" ];
      switch-to-session-3 = [ "<Primary><Alt>F3" ];
      switch-to-session-4 = [ "<Primary><Alt>F4" ];
      switch-to-session-5 = [ "<Primary><Alt>F5" ];
      switch-to-session-6 = [ "<Primary><Alt>F6" ];
      switch-to-session-7 = [ "<Primary><Alt>F7" ];
      switch-to-session-8 = [ "<Primary><Alt>F8" ];
      switch-to-session-9 = [ "<Primary><Alt>F9" ];
      switch-to-session-10 = [ "<Primary><Alt>F10" ];
      switch-to-session-11 = [ "<Primary><Alt>F11" ];
      switch-to-session-12 = [ "<Primary><Alt>F12" ];
    };

    "org/gnome/desktop/screensaver" = {
      picture-uri = "file:///home/nelson/Pictures/Wallpapers/lockscreen.jpg";
      picture-uri-dark = "file:///home/nelson/Pictures/Wallpapers/lockscreen.jpg";
    };

    "org/gnome/desktop/background" = {
      picture-uri = "file:///home/nelson/Pictures/Wallpapers/desktop.jpg";
      picture-uri-dark = "file:///home/nelson/Pictures/Wallpapers/desktop.jpg";
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "ULauncher";
      command = "ulauncher-toggle";
      binding = "<Alt>Space";
    };

    # "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
    #   name = "Albert Launcher";
    #   command = "albert --platformtheme gnome toggle";
    #   binding = "<Alt>Space";
    # };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Terminal";
      command = "ghostty";
      binding = "<Super>Return";
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

    # Extension settings

    "org/gnome/shell/extensions/pop-shell" = {
      activate-launcher = [ ];
      fullscreen-launcher = false;
      show-title = true;
      smart-gaps = false;
      snap-to-grid = false;
      stacking-with-mouse = false;

      gap-inner = mkUint32 3;
      gap-outer = mkUint32 3;

      tile-by-default = true;

      tile-enter = [ "<Super><Shift>Return" ];

      tile-move-left = [ ];
      tile-move-right = [ ];
      tile-move-up = [ ];
      tile-move-down = [ ];

      tile-move-left-global = [ "<Super><Shift>h" ];
      tile-move-right-global = [ "<Super><Shift>l" ];
      tile-move-up-global = [ "<Super><Shift>k" ];
      tile-move-down-global = [ "<Super><Shift>j" ];

      stack = [ ];
      toggle-floating = [ "<Meta><Shift>Space" ];
    };

    "org/gnome/shell/extensions/space-bar/behavior" = {
      always-show-numbers = false;
      position = "left";
      scroll-wheel = "workspaces-bar";
      show-empty-workspaces = true;
      toggle-overview = false;
    };

    "org/gnome/shell/extensions/space-bar/shortcuts" = {
      enable-activate-workspace-shortcuts = true;
      enable-move-to-workspace-shortcuts = true;
    };

    "org/gnome/shell/extensions/top-bar-organizer" = {
      left-box-order = [
        "activities"
        "Space Bar"
      ];
      center-box-order = [ "dateMenu" ];
      right-box-order = [
        "freonMenu"
        "screenSharing"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "dwellClick"
        "vitalsMenu"
        "a11y"
        "color-picker@tuberry"
        "screenRecording"
        "wol@mnorlin.se"
        "keyboard"
        "pop-shell"
        "quickSettings"
      ];
    };

    "org/gnome/shell/extensions/system-monitor" = {
      show-cpu = true;
      show-memory = true;
      show-swap = true;
      show-download = true;
      show-upload = true;
    };
  };
}
