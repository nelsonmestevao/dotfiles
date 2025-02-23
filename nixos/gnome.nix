# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "apps/seahorse/listing" = {
      keyrings-selected = [ "secret-service:///org/freedesktop/secrets/collection/login" ];
    };

    "apps/seahorse/windows/key-manager" = {
      height = 598;
      width = 913;
    };

    "org/gnome/Connections" = {
      first-run = false;
    };

    "org/gnome/Console" = {
      last-window-maximised = false;
      last-window-size = mkTuple [
        2536
        1520
      ];
    };

    "org/gnome/Extensions" = {
      window-height = 1544;
      window-maximized = false;
      window-width = 1262;
    };

    "org/gnome/Music" = {
      window-maximized = false;
    };

    "org/gnome/Snapshot" = {
      capture-mode = "picture";
      is-maximized = false;
      last-camera-id = "Laptop Camera (V4L2)";
      window-height = 1544;
      window-width = 1262;
    };

    "org/gnome/Weather" = {
      window-height = 1544;
      window-maximized = false;
      window-width = 1262;
    };

    "org/gnome/baobab/ui" = {
      is-maximized = false;
      window-size = mkTuple [
        960
        600
      ];
    };

    "org/gnome/control-center" = {
      last-panel = "privacy";
      window-state = mkTuple [
        1262
        1384
        false
      ];
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [
        "YaST"
        "Pardus"
      ];
    };

    "org/gnome/desktop/app-folders/folders/Pardus" = {
      categories = [ "X-Pardus-Apps" ];
      name = "X-Pardus-Apps.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/YaST" = {
      categories = [ "X-SuSE-YaST" ];
      name = "suse-yast.directory";
      translate = true;
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///home/nelson/.local/share/backgrounds/2025-02-20-23-36-29-desktop.jpg";
      picture-uri-dark = "file:///home/nelson/.local/share/backgrounds/2025-02-20-23-36-29-desktop.jpg";
      primary-color = "#000000000000";
      secondary-color = "#000000000000";
    };

    "org/gnome/desktop/input-sources" = {
      mru-sources = [
        (mkTuple [
          "xkb"
          "pt"
        ])
      ];
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

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      font-antialiasing = "grayscale";
      font-hinting = "slight";
      gtk-enable-primary-paste = false;
      icon-theme = "Adwaita";
      show-battery-percentage = true;
      text-scaling-factor = 1.0;
    };

    "org/gnome/desktop/media-handling" = {
      autorun-never = false;
    };

    "org/gnome/desktop/notifications" = {
      application-children = [
        "org-gnome-console"
        "firefox"
        "gnome-power-panel"
        "org-gnome-software"
        "app-zen-browser-zen"
        "org-gnome-settings"
      ];
      show-banners = true;
      show-in-lock-screen = true;
    };

    "org/gnome/desktop/notifications/application/app-zen-browser-zen" = {
      application-id = "app.zen_browser.zen.desktop";
    };

    "org/gnome/desktop/notifications/application/firefox" = {
      application-id = "firefox.desktop";
    };

    "org/gnome/desktop/notifications/application/gnome-power-panel" = {
      application-id = "gnome-power-panel.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-console" = {
      application-id = "org.gnome.Console.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-settings" = {
      application-id = "org.gnome.Settings.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-software" = {
      application-id = "org.gnome.Software.desktop";
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "default";
      left-handed = false;
      natural-scroll = false;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      disable-while-typing = true;
      edge-scrolling-enabled = false;
      natural-scroll = true;
      send-events = "enabled";
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///home/nelson/Pictures/Wallpapers/desktop.jpg";
      primary-color = "#000000000000";
      secondary-color = "#000000000000";
    };

    "org/gnome/desktop/search-providers" = {
      sort-order = [
        "org.gnome.Settings.desktop"
        "org.gnome.Contacts.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      activate-window-menu = [ ];
      close = [ "<Super>q" ];
      move-to-workspace-1 = [ "<Super><Shift>1" ];
      move-to-workspace-10 = [ "<Super><Shift>0" ];
      move-to-workspace-2 = [ "<Super><Shift>2" ];
      move-to-workspace-3 = [ "<Super><Shift>3" ];
      move-to-workspace-4 = [ "<Super><Shift>4" ];
      move-to-workspace-5 = [ "<Super><Shift>5" ];
      move-to-workspace-6 = [ "<Super><Shift>6" ];
      move-to-workspace-7 = [ "<Super><Shift>7" ];
      move-to-workspace-8 = [ "<Super><Shift>8" ];
      move-to-workspace-9 = [ "<Super><Shift>9" ];
      switch-input-source = [ "<Super>space" ];
      toggle-maximized = [ "<Super>f" ];
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "close,minimize,maximize:appmenu";
      focus-mode = "click";
      num-workspaces = 8;
      resize-with-right-button = false;
    };

    "org/gnome/epiphany/state" = {
      is-maximized = true;
      window-size = mkTuple [
        2560
        1568
      ];
    };

    "org/gnome/evolution-data-server" = {
      migrated = true;
    };

    "org/gnome/file-roller/listing" = {
      list-mode = "as-folder";
      show-path = false;
      sort-method = "name";
      sort-type = "ascending";
    };

    "org/gnome/file-roller/ui" = {
      sidebar-width = 200;
      window-height = 1544;
      window-width = 1262;
    };

    "org/gnome/gnome-system-monitor" = {
      maximized = false;
      show-dependencies = false;
      show-whose-processes = "user";
      window-height = 720;
      window-width = 800;
    };

    "org/gnome/gnome-system-monitor/proctree" = {
      col-26-visible = false;
      col-26-width = 0;
    };

    "org/gnome/mutter" = {
      attach-modal-dialogs = false;
      center-new-windows = false;
      dynamic-workspaces = false;
      edge-tiling = false;
      workspaces-only-on-primary = true;
    };

    "org/gnome/mutter/wayland/keybindings" = {
      restore-shortcuts = [ ];
    };

    "org/gnome/nautilus/icon-view" = {
      default-zoom-level = "small-plus";
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
    };

    "org/gnome/nautilus/window-state" = {
      initial-size = mkTuple [
        1262
        1544
      ];
      initial-size-file-chooser = mkTuple [
        890
        550
      ];
    };

    "org/gnome/portal/filechooser/app/zen_browser/zen" = {
      last-folder-path = "/home/nelson/Downloads";
    };

    "org/gnome/portal/filechooser/org/gnome/Settings" = {
      last-folder-path = "/home/nelson/Pictures/Wallpapers";
    };

    "org/gnome/portal/filechooser/pt/gov/autenticacao" = {
      last-folder-path = "/home/nelson/Downloads";
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-automatic = false;
      night-light-temperature = mkUint32 2000;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      control-center = [ "<Super>i" ];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
      home = [ "<Super>e" ];
      screensaver = [ "<Super>Escape" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Alt>space";
      command = "ulauncher-toggle";
      name = "ULauncher";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Super>Return";
      command = "ghostty";
      name = "Terminal";
    };

    "org/gnome/settings-daemon/plugins/power" = {
      power-button-action = "interactive";
      worspaces-only-on-primary = true;
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      disabled-extensions = [
        "light-style@gnome-shell-extensions.gcampax.github.com"
        "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com"
        "status-icons@gnome-shell-extensions.gcampax.github.com"
        "blurmylightshell@dikasp.gitlab"
        "native-window-placement@gnome-shell-extensions.gcampax.github.com"
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
      ];
      enabled-extensions = [
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        "blur-my-shell@aunetx"
        "pop-shell@system76.com"
        "space-bar@luchrioh"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
      ];
      favorite-apps = [
        "slack.desktop"
        "com.mitchellh.ghostty.desktop"
        "app.zen_browser.zen.desktop"
        "org.gnome.Nautilus.desktop"
        "spotify.desktop"
      ];
      last-selected-power-profile = "performance";
      welcome-dialog-last-shown-version = "47.2";
    };

    "org/gnome/shell/app-switcher" = {
      current-workspace-only = false;
    };

    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      brightness = 0.6;
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      brightness = 0.6;
      sigma = 30;
      static-blur = true;
      style-dash-to-dock = 0;
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      brightness = 0.6;
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/window-list" = {
      brightness = 0.6;
      sigma = 30;
    };

    "org/gnome/shell/extensions/pop-shell" = {
      fullscreen-launcher = false;
      gap-inner = mkUint32 3;
      gap-outer = mkUint32 3;
      log-level = mkUint32 4;
      show-skip-taskbar = true;
      show-title = false;
      smart-gaps = false;
      snap-to-grid = false;
      tile-by-default = true;
      tile-enter = [ "<Super><Shift>Return" ];
    };

    "org/gnome/shell/extensions/space-bar/appearance" = {
      application-styles = ".space-bar {n  -natural-hpadding: 12px;n}nn.space-bar-workspace-label.active {n  margin: 0 4px;n  background-color: rgba(255,255,255,0.3);n  color: rgba(255,255,255,1);n  border-color: rgba(0,0,0,0);n  font-weight: 700;n  border-radius: 4px;n  border-width: 0px;n  padding: 3px 8px;n}nn.space-bar-workspace-label.inactive {n  margin: 0 4px;n  background-color: rgba(0,0,0,0);n  color: rgba(255,255,255,1);n  border-color: rgba(0,0,0,0);n  font-weight: 700;n  border-radius: 4px;n  border-width: 0px;n  padding: 3px 8px;n}nn.space-bar-workspace-label.inactive.empty {n  margin: 0 4px;n  background-color: rgba(0,0,0,0);n  color: rgba(255,255,255,0.5);n  border-color: rgba(0,0,0,0);n  font-weight: 700;n  border-radius: 4px;n  border-width: 0px;n  padding: 3px 8px;n}";
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

    "org/gnome/shell/extensions/space-bar/state" = {
      version = 32;
    };

    "org/gnome/shell/extensions/system-monitor" = {
      show-cpu = true;
      show-download = true;
      show-memory = true;
      show-swap = true;
      show-upload = true;
    };

    "org/gnome/shell/weather" = {
      automatic-location = true;
      locations = [ ];
    };

    "org/gnome/shell/world-clocks" = {
      locations = [ ];
    };

    "org/gnome/software" = {
      check-timestamp = mkInt64 1740220636;
      first-run = false;
      flatpak-purge-timestamp = mkInt64 1740063115;
    };

    "org/gnome/tweaks" = {
      show-extensions-notice = false;
    };

    "xyz/ketok/Speedtest" = {
      height = 1262;
      width = 1416;
    };

  };
}
