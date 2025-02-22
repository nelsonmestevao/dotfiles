# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "ca/desrt/dconf-editor" = {
      saved-pathbar-path = "/org/gnome/tweaks/show-extensions-notice";
      saved-view = "/org/gnome/tweaks/show-extensions-notice";
      window-height = 1329;
      window-is-maximized = false;
      window-width = 2528;
    };

    "org/fedorahosted/background-logo-extension" = {
      logo-position = "bottom-right";
      logo-size = 15.0;
    };

    "org/freedesktop/folks" = {
      primary-store = "eds:d6e2b769cffec8075c3abda0a30dea628a39f6a6";
    };

    "org/gnome/Characters" = {
      recent-characters = [ "\127816" ];
    };

    "org/gnome/Connections" = {
      first-run = false;
    };

    "org/gnome/Contacts" = {
      did-initial-setup = true;
      window-fullscreen = false;
      window-height = 686;
      window-maximized = false;
      window-width = 1262;
    };

    "org/gnome/GPaste" = {
      track-changes = true;
    };

    "org/gnome/Loupe" = {
      show-properties = true;
    };

    "org/gnome/Snapshot" = {
      capture-mode = "picture";
      is-maximized = false;
      last-camera-id = "Microsoft\174 LifeCam Studio(TM) (V4L2)";
      window-height = 1376;
      window-width = 832;
    };

    "org/gnome/Totem" = {
      active-plugins = [ "vimeo" "variable-rate" "skipto" "screenshot" "screensaver" "save-file" "rotation" "recent" "movie-properties" "open-directory" "mpris" "autoload-subtitles" "apple-trailers" ];
      subtitle-encoding = "UTF-8";
    };

    "org/gnome/Weather" = {
      window-height = 1384;
      window-maximized = false;
      window-width = 1262;
    };

    "org/gnome/baobab/ui" = {
      is-maximized = false;
      window-size = mkTuple [ 1256 680 ];
    };

    "org/gnome/boxes" = {
      first-run = false;
      view = "icon-view";
      window-maximized = false;
      window-position = [ 26 23 ];
      window-size = [ 1256 1376 ];
    };

    "org/gnome/calculator" = {
      accuracy = 9;
      angle-units = "degrees";
      base = 10;
      button-mode = "basic";
      number-format = "automatic";
      show-thousands = false;
      show-zeroes = false;
      source-currency = "";
      source-units = "degree";
      target-currency = "";
      target-units = "radian";
      window-maximized = false;
      window-size = mkTuple [ 360 625 ];
      word-size = 64;
    };

    "org/gnome/calendar" = {
      active-view = "month";
      window-maximized = false;
      window-size = mkTuple [ 1256 680 ];
    };

    "org/gnome/clocks/state/window" = {
      maximized = false;
      panel-id = "world";
      size = mkTuple [ 744 896 ];
    };

    "org/gnome/control-center" = {
      last-panel = "applications";
      window-state = mkTuple [ 2536 1384 false ];
    };

    "org/gnome/desktop/a11y" = {
      always-show-universal-access-status = false;
    };

    "org/gnome/desktop/a11y/applications" = {
      screen-reader-enabled = false;
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [ "Utilities" "YaST" "Pardus" ];
    };

    "org/gnome/desktop/app-folders/folders/Pardus" = {
      categories = [ "X-Pardus-Apps" ];
      name = "X-Pardus-Apps.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [ "gnome-abrt.desktop" "gnome-system-log.desktop" "nm-connection-editor.desktop" "org.gnome.baobab.desktop" "org.gnome.Connections.desktop" "org.gnome.DejaDup.desktop" "org.gnome.Dictionary.desktop" "org.gnome.DiskUtility.desktop" "org.gnome.Evince.desktop" "org.gnome.FileRoller.desktop" "org.gnome.fonts.desktop" "org.gnome.Loupe.desktop" "org.gnome.seahorse.Application.desktop" "org.gnome.tweaks.desktop" "org.gnome.Usage.desktop" "vinagre.desktop" ];
      categories = [ "X-GNOME-Utilities" ];
      name = "X-GNOME-Utilities.directory";
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
      picture-uri = "file:///home/nelson/.local/share/backgrounds/2024-10-20-10-00-30-desktop.jpg";
      picture-uri-dark = "file:///home/nelson/.local/share/backgrounds/2024-10-20-10-00-30-desktop.jpg";
      primary-color = "#000000000000";
      secondary-color = "#000000000000";
    };

    "org/gnome/desktop/calendar" = {
      show-weekdate = false;
    };

    "org/gnome/desktop/datetime" = {
      automatic-timezone = false;
    };

    "org/gnome/desktop/input-sources" = {
      current = mkUint32 0;
      mru-sources = [ (mkTuple [ "xkb" "us" ]) (mkTuple [ "xkb" "pt" ]) ];
      sources = [ (mkTuple [ "xkb" "pt" ]) (mkTuple [ "xkb" "us" ]) ];
      xkb-options = [ "caps:ctrl_modifier" ];
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
      show-battery-percentage = true;
      toolkit-accessibility = false;
    };

    "org/gnome/desktop/media-handling" = {
      autorun-never = true;
    };

    "org/gnome/desktop/notifications" = {
      application-children = [ "org-gnome-software" "org-gnome-terminal" "org-wezfurlong-wezterm" "gnome-power-panel" "org-freedesktop-problems-applet" "org-gnome-calendar" "ulauncher" "com-spotify-client" "com-slack-slack" "com-jeffser-alpaca" "org-telegram-desktop" "org-mozilla-thunderbird" "org-gnome-evolution-alarm-notify" "org-gimp-gimp" "org-gnome-nautilus" "com-google-chrome" "org-gnome-shell-portalhelper" "org-fedoraproject-mediawriter" "com-mattjakeman-extensionmanager" "org-gnome-loupe" "org-gnome-shell-extensions" "org-gnome-evince" "code" "org-gnome-settings" "org-gnome-systemmonitor" "com-mitchellh-ghostty" "org-gnome-dejadup" "io-dbeaver-dbeavercommunity" "app-zen-browser-zen" "org-audacityteam-audacity" "xdg-desktop-portal-gnome" "org-inkscape-inkscape" ];
      show-banners = true;
    };

    "org/gnome/desktop/notifications/application/app-zen-browser-zen" = {
      application-id = "app.zen_browser.zen.desktop";
    };

    "org/gnome/desktop/notifications/application/code" = {
      application-id = "code.desktop";
    };

    "org/gnome/desktop/notifications/application/com-google-chrome" = {
      application-id = "com.google.Chrome.desktop";
    };

    "org/gnome/desktop/notifications/application/com-jeffser-alpaca" = {
      application-id = "com.jeffser.Alpaca.desktop";
    };

    "org/gnome/desktop/notifications/application/com-mattjakeman-extensionmanager" = {
      application-id = "com.mattjakeman.ExtensionManager.desktop";
    };

    "org/gnome/desktop/notifications/application/com-mitchellh-ghostty" = {
      application-id = "com.mitchellh.ghostty.desktop";
    };

    "org/gnome/desktop/notifications/application/com-slack-slack" = {
      application-id = "com.slack.Slack.desktop";
    };

    "org/gnome/desktop/notifications/application/com-spotify-client" = {
      application-id = "com.spotify.Client.desktop";
    };

    "org/gnome/desktop/notifications/application/gnome-power-panel" = {
      application-id = "gnome-power-panel.desktop";
    };

    "org/gnome/desktop/notifications/application/io-dbeaver-dbeavercommunity" = {
      application-id = "io.dbeaver.DBeaverCommunity.desktop";
    };

    "org/gnome/desktop/notifications/application/org-audacityteam-audacity" = {
      application-id = "org.audacityteam.Audacity.desktop";
    };

    "org/gnome/desktop/notifications/application/org-fedoraproject-mediawriter" = {
      application-id = "org.fedoraproject.MediaWriter.desktop";
    };

    "org/gnome/desktop/notifications/application/org-freedesktop-problems-applet" = {
      application-id = "org.freedesktop.problems.applet.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gimp-gimp" = {
      application-id = "org.gimp.GIMP.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-calendar" = {
      application-id = "org.gnome.Calendar.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-dejadup" = {
      application-id = "org.gnome.DejaDup.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-evince" = {
      application-id = "org.gnome.Evince.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-evolution-alarm-notify" = {
      application-id = "org.gnome.Evolution-alarm-notify.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-loupe" = {
      application-id = "org.gnome.Loupe.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-nautilus" = {
      application-id = "org.gnome.Nautilus.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-settings" = {
      application-id = "org.gnome.Settings.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-shell-extensions" = {
      application-id = "org.gnome.Shell.Extensions.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-shell-portalhelper" = {
      application-id = "org.gnome.Shell.PortalHelper.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-software" = {
      application-id = "org.gnome.Software.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-systemmonitor" = {
      application-id = "org.gnome.SystemMonitor.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-terminal" = {
      application-id = "org.gnome.Terminal.desktop";
    };

    "org/gnome/desktop/notifications/application/org-inkscape-inkscape" = {
      application-id = "org.inkscape.Inkscape.desktop";
    };

    "org/gnome/desktop/notifications/application/org-mozilla-thunderbird" = {
      application-id = "org.mozilla.Thunderbird.desktop";
    };

    "org/gnome/desktop/notifications/application/org-telegram-desktop" = {
      application-id = "org.telegram.desktop.desktop";
    };

    "org/gnome/desktop/notifications/application/org-wezfurlong-wezterm" = {
      application-id = "org.wezfurlong.wezterm.desktop";
    };

    "org/gnome/desktop/notifications/application/ulauncher" = {
      application-id = "ulauncher.desktop";
    };

    "org/gnome/desktop/notifications/application/xdg-desktop-portal-gnome" = {
      application-id = "xdg-desktop-portal-gnome.desktop";
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "default";
      natural-scroll = false;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      disable-while-typing = true;
      natural-scroll = true;
      send-events = "enabled";
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/privacy" = {
      old-files-age = mkUint32 30;
      recent-files-max-age = -1;
      report-technical-problems = true;
    };

    "org/gnome/desktop/remote-desktop/rdp" = {
      enable = false;
      tls-cert = "/home/nelson/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt";
      tls-key = "/home/nelson/.local/share/gnome-remote-desktop/certificates/rdp-tls.key";
      view-only = true;
    };

    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///home/nelson/Pictures/Wallpapers/desktop.jpg";
      primary-color = "#000000000000";
      secondary-color = "#000000000000";
    };

    "org/gnome/desktop/search-providers" = {
      enabled = [ "org.gnome.Weather.desktop" ];
      sort-order = [ "org.gnome.Contacts.desktop" "org.gnome.Documents.desktop" "org.gnome.Nautilus.desktop" ];
    };

    "org/gnome/desktop/session" = {
      idle-delay = mkUint32 0;
    };

    "org/gnome/desktop/sound" = {
      event-sounds = false;
    };

    "org/gnome/desktop/wm/keybindings" = {
      activate-window-menu = [];
      close = [ "<Super>q" ];
      maximize = [];
      minimize = [ "<Super>comma" ];
      move-to-monitor-down = [];
      move-to-monitor-left = [];
      move-to-monitor-right = [];
      move-to-monitor-up = [];
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
      move-to-workspace-down = [];
      move-to-workspace-up = [];
      switch-input-source = [ "<Super>space" ];
      switch-input-source-backward = [ "<Shift><Super>space" ];
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-10 = [ "<Super>0" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      switch-to-workspace-5 = [ "<Super>5" ];
      switch-to-workspace-6 = [ "<Super>6" ];
      switch-to-workspace-7 = [ "<Super>7" ];
      switch-to-workspace-8 = [ "<Super>8" ];
      switch-to-workspace-9 = [ "<Super>9" ];
      switch-to-workspace-down = [ "<Primary><Super>Down" "<Primary><Super>j" ];
      switch-to-workspace-left = [];
      switch-to-workspace-right = [];
      switch-to-workspace-up = [ "<Primary><Super>Up" "<Primary><Super>k" ];
      toggle-fullscreen = [];
      toggle-maximized = [ "<Super>f" ];
      unmaximize = [];
    };

    "org/gnome/desktop/wm/preferences" = {
      action-double-click-titlebar = "toggle-maximize";
      button-layout = "close,minimize,maximize:appmenu";
      num-workspaces = 8;
      workspace-names = [];
    };

    "org/gnome/evince" = {
      document-directory = "file:///home/nelson/.var/app/org.telegram.desktop/data/TelegramDesktop/tdata/temp_data";
    };

    "org/gnome/evince/default" = {
      continuous = true;
      dual-page = false;
      dual-page-odd-left = true;
      enable-spellchecking = true;
      fullscreen = false;
      inverted-colors = false;
      show-sidebar = false;
      sidebar-page = "thumbnails";
      sidebar-size = 148;
      sizing-mode = "free";
      window-ratio = mkTuple [ 2.1099314608251576 0.8077064699663852 ];
      zoom = 0.401877572016461;
    };

    "org/gnome/evolution-data-server" = {
      migrated = true;
    };

    "org/gnome/evolution-data-server/calendar" = {
      reminders-past = [ "b98baf581b742271e828ac6ff7ed4e450a9d8dbfn6e077afabaefaf3d36dbe4e2009ca8b7e01bcaadt20250221T140000Zn1740144600n1740146400n1740152400nBEGIN:VEVENTrnDTSTART;TZID=Europe/Lisbon:20250221T140000rnDTEND;TZID=Europe/Lisbon:20250221T154000rnRRULE:FREQ=WEEKLY;UNTIL=20250510T225959Z;BYDAY=FRrnEXDATE;TZID=Europe/Lisbon:20250418T140000rnEXDATE;TZID=Europe/Lisbon:20250425T140000rnDTSTAMP:20250213T214050ZrnUID:2dpu3gsinrsi7agbfplm8b6kdf@google.comrnCREATED:20250213T204206ZrnDESCRIPTION:rnLAST-MODIFIED:20250213T214050ZrnLOCATION:CG - Edif\237cio 1 - 2.21rnSEQUENCE:1rnSTATUS:CONFIRMEDrnSUMMARY:[PI - LCC/TP1] Aula Te\243rico-Pr\225ticarnTRANSP:OPAQUErnX-EVOLUTION-CALDAV-ETAG:63875166050rnRECURRENCE-ID:20250221T140000ZrnBEGIN:VALARMrnACTION:DISPLAYrnDESCRIPTION:This is an event reminderrnTRIGGER:-PT30MrnX-EVOLUTION-ALARM-UID:6e077afabaefaf3d36dbe4e2009ca8b7e01bcaadrnEND:VALARMrnEND:VEVENTrn" "b98baf581b742271e828ac6ff7ed4e450a9d8dbfn8ea0a8770948e8528246d65909bbc9eb5bca28d2t20250220T083000Zn1740038400n1740040200n1740043800nBEGIN:VEVENTrnDTSTART;TZID=Europe/Lisbon:20250220T083000rnDTEND;TZID=Europe/Lisbon:20250220T093000rnRRULE:FREQ=WEEKLYrnDTSTAMP:20250220T083048ZrnORGANIZER;CN=nelsonmestevao@gmail.com:mailto:nelsonmestevao@gmail.comrnUID:697o4nbb5u7cmprn7bfr342pc0@google.comrnATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;rn CN=nelsonmestevao@gmail.com;X-NUM-GUESTS=0:mailto:rn nelsonmestevao@gmail.comrnATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;rn CN=danielsp356@gmail.com;X-NUM-GUESTS=0:mailto:danielsp356@gmail.comrnATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;rn CN=joaoadelino.pereira@gmail.com;X-NUM-GUESTS=0:mailto:rn joaoadelino.pereira@gmail.comrnCREATED:20250220T083048ZrnDESCRIPTION:rnLAST-MODIFIED:20250220T083048ZrnLOCATION:rnSEQUENCE:0rnSTATUS:CONFIRMEDrnSUMMARY:\128095 CorridarnTRANSP:OPAQUErnX-EVOLUTION-CALDAV-ETAG:63875723448rnRECURRENCE-ID:20250220T083000ZrnBEGIN:VALARMrnACTION:DISPLAYrnDESCRIPTION:This is an event reminderrnTRIGGER:-PT30MrnX-EVOLUTION-ALARM-UID:8ea0a8770948e8528246d65909bbc9eb5bca28d2rnEND:VALARMrnBEGIN:VALARMrnACTION:DISPLAYrnDESCRIPTION:This is an event reminderrnTRIGGER:-P1DrnX-EVOLUTION-ALARM-UID:b33ae7db511b31c91ff005905bf8a98652366b35rnEND:VALARMrnEND:VEVENTrn" "b98baf581b742271e828ac6ff7ed4e450a9d8dbfnb33ae7db511b31c91ff005905bf8a98652366b35t20250220T083000Zn1739953800n1740040200n1740043800nBEGIN:VEVENTrnDTSTART;TZID=Europe/Lisbon:20250220T083000rnDTEND;TZID=Europe/Lisbon:20250220T093000rnRRULE:FREQ=WEEKLYrnDTSTAMP:20250220T083048ZrnORGANIZER;CN=nelsonmestevao@gmail.com:mailto:nelsonmestevao@gmail.comrnUID:697o4nbb5u7cmprn7bfr342pc0@google.comrnATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;rn CN=nelsonmestevao@gmail.com;X-NUM-GUESTS=0:mailto:rn nelsonmestevao@gmail.comrnATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;rn CN=danielsp356@gmail.com;X-NUM-GUESTS=0:mailto:danielsp356@gmail.comrnATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;rn CN=joaoadelino.pereira@gmail.com;X-NUM-GUESTS=0:mailto:rn joaoadelino.pereira@gmail.comrnCREATED:20250220T083048ZrnDESCRIPTION:rnLAST-MODIFIED:20250220T083048ZrnLOCATION:rnSEQUENCE:0rnSTATUS:CONFIRMEDrnSUMMARY:\128095 CorridarnTRANSP:OPAQUErnX-EVOLUTION-CALDAV-ETAG:63875723448rnRECURRENCE-ID:20250220T083000ZrnBEGIN:VALARMrnACTION:DISPLAYrnDESCRIPTION:This is an event reminderrnTRIGGER:-PT30MrnX-EVOLUTION-ALARM-UID:8ea0a8770948e8528246d65909bbc9eb5bca28d2rnEND:VALARMrnBEGIN:VALARMrnACTION:DISPLAYrnDESCRIPTION:This is an event reminderrnTRIGGER:-P1DrnX-EVOLUTION-ALARM-UID:b33ae7db511b31c91ff005905bf8a98652366b35rnEND:VALARMrnEND:VEVENTrn" "b98baf581b742271e828ac6ff7ed4e450a9d8dbfn6e077afabaefaf3d36dbe4e2009ca8b7e01bcaadt20250214T140000Zn1739539800n1739541600n1739547600nBEGIN:VEVENTrnDTSTART;TZID=Europe/Lisbon:20250214T140000rnDTEND;TZID=Europe/Lisbon:20250214T154000rnRRULE:FREQ=WEEKLY;UNTIL=20250510T225959Z;BYDAY=FRrnEXDATE;TZID=Europe/Lisbon:20250418T140000rnEXDATE;TZID=Europe/Lisbon:20250425T140000rnDTSTAMP:20250213T214050ZrnUID:2dpu3gsinrsi7agbfplm8b6kdf@google.comrnCREATED:20250213T204206ZrnDESCRIPTION:rnLAST-MODIFIED:20250213T214050ZrnLOCATION:CG - Edif\237cio 1 - 2.21rnSEQUENCE:1rnSTATUS:CONFIRMEDrnSUMMARY:[PI - LCC/TP1] Aula Te\243rico-Pr\225ticarnTRANSP:OPAQUErnX-EVOLUTION-CALDAV-ETAG:63875166050rnRECURRENCE-ID:20250214T140000ZrnBEGIN:VALARMrnACTION:DISPLAYrnDESCRIPTION:This is an event reminderrnTRIGGER:-PT30MrnX-EVOLUTION-ALARM-UID:6e077afabaefaf3d36dbe4e2009ca8b7e01bcaadrnEND:VALARMrnEND:VEVENTrn" ];
    };

    "org/gnome/evolution" = {
      default-address-book = "d6e2b769cffec8075c3abda0a30dea628a39f6a6";
    };

    "org/gnome/gnome-system-monitor" = {
      current-tab = "resources";
      maximized = false;
      show-dependencies = false;
      show-whose-processes = "user";
      window-height = 1384;
      window-width = 1262;
    };

    "org/gnome/gnome-system-monitor/proctree" = {
      col-26-visible = false;
      col-26-width = 0;
    };

    "org/gnome/login-screen" = {
      enable-fingerprint-authentication = true;
      enable-smartcard-authentication = false;
    };

    "org/gnome/maps" = {
      last-viewed-location = [ 41.54349477338041 (-8.421895394018748) ];
      map-type = "MapsVectorSource";
      transportation-type = "pedestrian";
      window-maximized = false;
      window-size = [ 1256 680 ];
      zoom-level = 16;
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = false;
      edge-tiling = false;
      workspaces-only-on-primary = true;
    };

    "org/gnome/mutter/wayland/keybindings" = {
      restore-shortcuts = [];
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
      initial-size = mkTuple [ 750 446 ];
      initial-size-file-chooser = mkTuple [ 1416 1262 ];
      maximized = false;
    };

    "org/gnome/nm-applet/eap/aa5d0343-4e47-4cd9-a791-f799dc655479" = {
      ignore-ca-cert = true;
      ignore-phase2-ca-cert = false;
    };

    "org/gnome/nm-applet/eap/d228ff44-d95e-43a9-88d7-85d37b2eede9" = {
      ignore-ca-cert = false;
      ignore-phase2-ca-cert = false;
    };

    "org/gnome/portal/filechooser/app/drey/Warp" = {
      last-folder-path = "/home/nelson";
    };

    "org/gnome/portal/filechooser/app/zen_browser/zen" = {
      last-folder-path = "/home/nelson/Documents/PI";
    };

    "org/gnome/portal/filechooser/com/belmoussaoui/Obfuscate" = {
      last-folder-path = "/home/nelson/Pictures";
    };

    "org/gnome/portal/filechooser/com/calibre_ebook/calibre" = {
      last-folder-path = "/home/nelson/Books";
    };

    "org/gnome/portal/filechooser/com/google/Chrome" = {
      last-folder-path = "/home/nelson/Downloads";
    };

    "org/gnome/portal/filechooser/com/slack/Slack" = {
      last-folder-path = "/home/nelson/Code/Marmela/livecomp.app";
    };

    "org/gnome/portal/filechooser/com/spotify/Client" = {
      last-folder-path = "/home/nelson/Downloads";
    };

    "org/gnome/portal/filechooser/io/gitlab/gregorni/Letterpress" = {
      last-folder-path = "/home/nelson/Pictures";
    };

    "org/gnome/portal/filechooser/md/obsidian/Obsidian" = {
      last-folder-path = "/home/nelson/Code/Personal/notes";
    };

    "org/gnome/portal/filechooser/org/gnome/DejaDup" = {
      last-folder-path = "/home/nelson/.keys";
    };

    "org/gnome/portal/filechooser/org/mozilla/Thunderbird" = {
      last-folder-path = "/home/nelson/Downloads";
    };

    "org/gnome/portal/filechooser/org/raspberrypi/rpi-imager" = {
      last-folder-path = "/home/nelson/Downloads";
    };

    "org/gnome/portal/filechooser/org/telegram/desktop" = {
      last-folder-path = "/home/nelson/Downloads";
    };

    "org/gnome/portal/filechooser/ulauncher" = {
      last-folder-path = "/home/nelson/Downloads";
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-last-coordinates = mkTuple [ 41.3408 (-8.31715) ];
      night-light-schedule-automatic = true;
      night-light-temperature = mkUint32 2000;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      control-center = [ "<Super>i" ];
      custom-keybindings = [ "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/" ];
      email = [];
      home = [ "<Super>e" ];
      rotate-video-lock-static = [];
      screensaver = [ "<Super>Escape" ];
      search = [];
      terminal = [ "<Super>t" ];
      www = [];
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
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-timeout = 5400;
      worspaces-only-on-primary = true;
    };

    "org/gnome/settings-daemon/plugins/sharing/gnome-user-share-webdav" = {
      enabled-connections = [];
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      disabled-extensions = [ "extension-list@tu.berry" "burn-my-windows@schneegans.github.com" "apps-menu@gnome-shell-extensions.gcampax.github.com" "launch-new-instance@gnome-shell-extensions.gcampax.github.com" "places-menu@gnome-shell-extensions.gcampax.github.com" "window-list@gnome-shell-extensions.gcampax.github.com" "background-logo@fedorahosted.org" "forge@jmmaranan.com" "trimmer@hedgie.tech" "simulate-switching-workspaces-on-active-monitor@micheledaros.com" "dynamic-panel@velhlkj.com" ];
      enabled-extensions = [ "auto-move-windows@gnome-shell-extensions.gcampax.github.com" "blur-my-shell@aunetx" "pop-shell@system76.com" "space-bar@luchrioh" "system-monitor@gnome-shell-extensions.gcampax.github.com" ];
      favorite-apps = [];
      last-selected-power-profile = "performance";
      remember-mount-password = false;
      welcome-dialog-last-shown-version = "46.0";
    };

    "org/gnome/shell/app-switcher" = {
      current-workspace-only = true;
    };

    "org/gnome/shell/extensions/auto-move-windows" = {
      application-list = [ "com.slack.Slack.desktop:1" "code.desktop:7" ];
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

    "org/gnome/shell/extensions/burn-my-windows" = {
      last-extension-version = 44;
    };

    "org/gnome/shell/extensions/clipboard-indicator" = {
      display-mode = 0;
      strip-text = true;
    };

    "org/gnome/shell/extensions/emoji-copy" = {
      always-show = false;
      recently-used = [ "\127803" "\128156" "\128525" "\128514" "\10084\65039" "\128557" "\128522" "\128530" "\128536" "\128553" "\129300" ];
    };

    "org/gnome/shell/extensions/extension-list" = {
      button-icon = mkUint32 1;
    };

    "org/gnome/shell/extensions/forge" = {
      css-last-update = mkUint32 37;
      css-updated = "1731859006058";
      dnd-center-layout = "swap";
      focus-border-toggle = false;
      move-pointer-focus-enabled = false;
      preview-hint-enabled = true;
      quick-settings-enabled = true;
      split-border-toggle = false;
      stacked-tiling-mode-enabled = false;
      tabbed-tiling-mode-enabled = false;
      tiling-mode-enabled = false;
      window-gap-hidden-on-single = false;
      window-gap-size = mkUint32 4;
      window-gap-size-increment = mkUint32 2;
      workspace-skip-tile = "";
    };

    "org/gnome/shell/extensions/forge/keybindings" = {
      con-split-horizontal = [ "<Super>z" ];
      con-split-layout-toggle = [ "<Super>g" ];
      con-split-vertical = [ "<Super>v" ];
      con-stacked-layout-toggle = [ "<Shift><Super>s" ];
      con-tabbed-layout-toggle = [];
      con-tabbed-showtab-decoration-toggle = [ "<Control><Alt>y" ];
      focus-border-toggle = [ "<Super>x" ];
      prefs-open = [];
      prefs-tiling-toggle = [ "<Super>w" ];
      window-focus-down = [ "<Super>j" ];
      window-focus-left = [ "<Super>h" ];
      window-focus-right = [ "<Super>l" ];
      window-focus-up = [ "<Super>k" ];
      window-gap-size-decrease = [ "<Control><Super>minus" ];
      window-gap-size-increase = [ "<Control><Super>plus" ];
      window-move-down = [ "<Shift><Super>j" ];
      window-move-left = [ "<Shift><Super>h" ];
      window-move-right = [ "<Shift><Super>l" ];
      window-move-up = [ "<Shift><Super>k" ];
      window-resize-bottom-decrease = [ "<Shift><Control><Super>i" ];
      window-resize-bottom-increase = [ "<Control><Super>u" ];
      window-resize-left-decrease = [ "<Shift><Control><Super>o" ];
      window-resize-left-increase = [ "<Control><Super>y" ];
      window-resize-right-decrease = [ "<Shift><Control><Super>y" ];
      window-resize-right-increase = [ "<Control><Super>o" ];
      window-resize-top-decrease = [ "<Shift><Control><Super>u" ];
      window-resize-top-increase = [ "<Control><Super>i" ];
      window-snap-center = [];
      window-snap-one-third-left = [];
      window-snap-one-third-right = [];
      window-snap-two-third-left = [];
      window-snap-two-third-right = [];
      window-swap-down = [ "<Control><Super>j" ];
      window-swap-last-active = [];
      window-swap-left = [ "<Control><Super>h" ];
      window-swap-right = [ "<Control><Super>l" ];
      window-swap-up = [ "<Control><Super>k" ];
      window-toggle-always-float = [];
      window-toggle-float = [];
      workspace-active-tile-toggle = [ "<Shift><Super>w" ];
    };

    "org/gnome/shell/extensions/openweatherrefined" = {
      has-run = true;
      weather-provider = "visualcrossing";
    };

    "org/gnome/shell/extensions/pop-shell" = {
      activate-launcher = [ "<Super>+" ];
      fullscreen-launcher = false;
      gap-inner = mkUint32 3;
      gap-outer = mkUint32 3;
      show-title = true;
      smart-gaps = false;
      snap-to-grid = false;
      stacking-with-mouse = false;
      tile-by-default = true;
      tile-enter = [ "<Super><Shift>Return" ];
      tile-move-down = [ "<Super><Shift>j" ];
      tile-move-left = [ "<Super><Shift>h" ];
      tile-move-left-global = [ "<Super><Shift>h" ];
      tile-move-right = [ "<Super><Shift>l" ];
      tile-move-up = [ "<Super><Shift>k" ];
      toggle-floating = [ "<Meta><Shift>Space" ];
    };

    "org/gnome/shell/extensions/quick-settings-tweaks" = {
      list-buttons = "[{\"name\":\"SystemItem\",\"title\":null,\"visible\":true},{\"name\":\"OutputStreamSlider\",\"title\":null,\"visible\":true},{\"name\":\"InputStreamSlider\",\"title\":null,\"visible\":false},{\"name\":\"St_BoxLayout\",\"title\":null,\"visible\":true},{\"name\":\"BrightnessItem\",\"title\":null,\"visible\":false},{\"name\":\"NMWiredToggle\",\"title\":null,\"visible\":false},{\"name\":\"NMWirelessToggle\",\"title\":\"Wi-Fi\",\"visible\":true},{\"name\":\"NMModemToggle\",\"title\":null,\"visible\":false},{\"name\":\"NMBluetoothToggle\",\"title\":null,\"visible\":false},{\"name\":\"NMVpnToggle\",\"title\":null,\"visible\":false},{\"name\":\"BluetoothToggle\",\"title\":\"Bluetooth\",\"visible\":true},{\"name\":\"PowerProfilesToggle\",\"title\":\"Power Mode\",\"visible\":true},{\"name\":\"NightLightToggle\",\"title\":\"Night Light\",\"visible\":true},{\"name\":\"DarkModeToggle\",\"title\":\"Dark Style\",\"visible\":true},{\"name\":\"KeyboardBrightnessToggle\",\"title\":\"Keyboard\",\"visible\":true},{\"name\":\"RfkillToggle\",\"title\":\"Airplane Mode\",\"visible\":true},{\"name\":\"RotationToggle\",\"title\":\"Auto Rotate\",\"visible\":false},{\"name\":\"DndQuickToggle\",\"title\":\"Do Not Disturb\",\"visible\":true},{\"name\":\"BackgroundAppsToggle\",\"title\":\"No Background Apps\",\"visible\":false},{\"name\":\"MediaSection\",\"title\":null,\"visible\":false},{\"name\":\"Notifications\",\"title\":null,\"visible\":true}]";
      output-show-selected = false;
      volume-mixer-show-icon = true;
    };

    "org/gnome/shell/extensions/space-bar/appearance" = {
      active-workspace-border-radius = 4;
      application-styles = ".space-bar {n  -natural-hpadding: 12px;n}nn.space-bar-workspace-label.active {n  margin: 0 4px;n  background-color: rgba(255,255,255,0.3);n  color: rgba(255,255,255,1);n  border-color: rgba(0,0,0,0);n  font-weight: 700;n  border-radius: 4px;n  border-width: 0px;n  padding: 3px 8px;n}nn.space-bar-workspace-label.inactive {n  margin: 0 4px;n  background-color: rgba(0,0,0,0);n  color: rgba(255,255,255,1);n  border-color: rgba(0,0,0,0);n  font-weight: 700;n  border-radius: 4px;n  border-width: 0px;n  padding: 3px 8px;n}nn.space-bar-workspace-label.inactive.empty {n  margin: 0 4px;n  background-color: rgba(0,0,0,0);n  color: rgba(255,255,255,0.5);n  border-color: rgba(0,0,0,0);n  font-weight: 700;n  border-radius: 4px;n  border-width: 0px;n  padding: 3px 8px;n}";
      custom-styles-enabled = false;
      custom-styles-failed = false;
      empty-workspace-border-radius = 4;
      inactive-workspace-border-radius = 4;
      workspace-margin = 4;
      workspaces-bar-padding = 12;
    };

    "org/gnome/shell/extensions/space-bar/behavior" = {
      always-show-numbers = false;
      indicator-style = "workspaces-bar";
      position = "left";
      scroll-wheel = "workspaces-bar";
      show-empty-workspaces = true;
      smart-workspace-names = false;
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

    "org/gnome/shell/extensions/vitals" = {
      fixed-widths = true;
      hide-icons = false;
      hide-zeros = false;
      icon-style = 1;
      include-static-info = true;
      menu-centered = false;
      position-in-panel = 2;
      show-battery = false;
      show-gpu = false;
      show-processor = true;
      show-system = true;
      show-temperature = true;
      use-higher-precision = false;
    };

    "org/gnome/shell/keybindings" = {
      open-application-menu = [];
      switch-to-application-1 = [];
      switch-to-application-2 = [];
      switch-to-application-3 = [];
      switch-to-application-4 = [];
    };

    "org/gnome/shell/weather" = {
      automatic-location = true;
      locations = [];
    };

    "org/gnome/shell/world-clocks" = {
      locations = [];
    };

    "org/gnome/software" = {
      check-timestamp = mkInt64 1740130813;
      first-run = false;
      flatpak-purge-timestamp = mkInt64 1740152635;
      install-timestamp = mkInt64 1739017430;
      update-notification-timestamp = mkInt64 1739024276;
      upgrade-notification-timestamp = mkInt64 1730393761;
    };

    "org/gnome/system/location" = {
      enabled = true;
    };

    "org/gnome/terminal/legacy" = {
      theme-variant = "system";
    };

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      font = "JetBrainsMono Nerd Font Mono 18";
      use-system-font = false;
      visible-name = "Development";
    };

    "org/gnome/tweaks" = {
      show-extensions-notice = false;
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      sidebar-width = 140;
      sort-column = "name";
      sort-directories-first = false;
      sort-order = "ascending";
      type-format = "category";
      view-type = "list";
      window-size = mkTuple [ 860 589 ];
    };

    "org/gtk/settings/file-chooser" = {
      clock-format = "24h";
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = true;
      show-size-column = true;
      show-type-column = true;
      sidebar-width = 157;
      sort-column = "name";
      sort-directories-first = false;
      sort-order = "ascending";
      type-format = "category";
      window-position = mkTuple [ 26 23 ];
      window-size = mkTuple [ 1231 881 ];
    };

    "org/virt-manager/virt-manager" = {
      manager-window-height = 1347;
      manager-window-width = 2536;
    };

    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };

    "org/virt-manager/virt-manager/details" = {
      show-toolbar = true;
    };

    "org/virt-manager/virt-manager/vmlist-fields" = {
      disk-usage = false;
      network-traffic = false;
    };

    "org/virt-manager/virt-manager/vms/29c3be3dca85499ea7ec9b33d2d827f3" = {
      autoconnect = 1;
      vm-window-size = mkTuple [ 1256 643 ];
    };

    "system/locale" = {
      region = "en_GB.UTF-8";
    };

    "xyz/ketok/Speedtest" = {
      height = 1152;
      width = 948;
    };

  };
}
