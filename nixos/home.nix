{
  config,
  lib,
  pkgs,
  ...
}:

with lib.hm.gvariant;

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "nelson";
  home.homeDirectory = "/home/nelson";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # shell
    zsh
    # dev tools
    bat
    bruno
    caddy
    cloudflared
    curl
    delta
    difftastic
    eza
    fd
    fzf
    gh
    git
    gitleaks
    jq
    k6
    stripe-cli
    # mise
    neovim
    ripgrep
    shellcheck
    shfmt
    wget
    yazi
    zoxide
    # dev utils
    autoconf
    automake
    btop
    fop
    gcc
    gnumake
    hyperfine
    inotify-tools
    llvmPackages_20.clang-tools
    pkg-config
    podman
    podman-compose
    speedtest-cli
    unzip
    watchman
    # tools
    bitwarden-cli
    bitwarden-desktop
    ffmpeg-full
    imagemagick
    impression
    inkscape
    libreoffice
    sc-im
    # system tools
    neofetch
    onefetch

    # build Erlang/OTP with Kerl
    # flex
    # gnused
    # libGL
    # libGLU
    # libressl
    # ncurses
    # openjdk
    # openssl
    # perl
    # termcap
    # unixODBC
    # wxGTK32
    # wxc

    # gnome
    wmctrl
    gnome-tweaks
    ulauncher
    wl-clipboard
    copyq

    # Gnome Extensions
    gnomeExtensions.auto-move-windows
    gnomeExtensions.blur-my-shell
    gnomeExtensions.pop-shell
    gnomeExtensions.space-bar
    gnomeExtensions.system-monitor
    gnomeExtensions.caffeine

    elixir_1_18
    erlang_27
    ruby_3_4
    nodejs_23

    file
    image_optim
    # jpegoptim
    # optipng
    # pngquant
    # nodePackages.svgo
    # gifsicle

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  systemd.user.services.ulauncher = {
    Unit = {
      Description = "Linux Application Launcher";
      Documentation = "https://ulauncher.io/";
    };
    Service = {
      Type = "simple";
      Restart = "always";
      RestartSec = 1;
      Environment = "GDK_BACKEND=x11";
      ExecStart = "${pkgs.ulauncher}/bin/ulauncher --hide-window";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  services.copyq = {
    enable = true;
  };

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false; # enables user extensions
      enabled-extensions = [
        pkgs.gnomeExtensions.auto-move-windows.extensionUuid
        pkgs.gnomeExtensions.blur-my-shell.extensionUuid
        pkgs.gnomeExtensions.pop-shell.extensionUuid
        pkgs.gnomeExtensions.space-bar.extensionUuid
        pkgs.gnomeExtensions.system-monitor.extensionUuid
        pkgs.gnomeExtensions.caffeine.extensionUuid

        # Alternatively, you can manually pass UUID as a string.
        # "blur-my-shell@aunetx"
        # ...
      ];
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
      show-battery-percentage = true;
      toolkit-accessibility = false;
    };

    "org/gnome/desktop/media-handling" = {
      autorun-never = false;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "close,minimize,maximize:appmenu";
      num-workspaces = 8;
    };

    "org/gnome/shell/keybindings" = {
      switch-to-application-1 = [ ];
      switch-to-application-2 = [ ];
      switch-to-application-3 = [ ];
      switch-to-application-4 = [ ];
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
      switch-input-source = [ "<Super>space" ];
      switch-input-source-backward = [ "<Shift><Super>space" ];
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

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "ULauncher";
      command = "ulauncher-toggle";
      binding = "<Alt>space";
    };

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
      tile-move-down = [ "<Super><Shift>j" ];
      tile-move-down-global = [ "<Super><Shift>j" ];
      tile-move-left = [ "<Super><Shift>h" ];
      tile-move-left-global = [ "<Super><Shift>h" ];
      tile-move-right = [ "<Super><Shift>l" ];
      tile-move-right-global = [ "<Super><Shift>l" ];
      tile-move-up = [ "<Super><Shift>k" ];
      tile-move-up-global = [ "<Super><Shift>k" ];
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

    "org/gnome/shell/extensions/system-monitor" = {
      show-cpu = true;
      show-memory = true;
      show-swap = true;
      show-download = true;
      show-upload = true;
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
