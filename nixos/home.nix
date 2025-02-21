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
    curl
    delta
    eza
    fd
    fzf
    git
    gitleaks
    jq
    mise
    neovim
    ripgrep
    shellcheck
    wget
    zoxide
    # tools
    sc-im
    # system tools
    neofetch
    onefetch

    # gnome
    wmctrl
    gnome-tweaks
    ulauncher

    # Gnome Extensions
    gnomeExtensions.auto-move-windows
    gnomeExtensions.blur-my-shell
    gnomeExtensions.pop-shell
    gnomeExtensions.space-bar
    gnomeExtensions.system-monitor

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

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/nelson/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
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

        # Alternatively, you can manually pass UUID as a string.
        # "blur-my-shell@aunetx"
        # ...
      ];
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-automatic = true;
      night-light-temperature = mkUint32 2000;
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
      icon-theme = "Adwaita";
      show-battery-percentage = true;
      gtk-enable-primary-paste = false;
    };

    "org/gnome/desktop/media-handling" = {
      autorun-never = false;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "close,minimize,maximize:appmenu";
      num-workspaces = 8;
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
      toggle-maximized = [ "<Super>f" ];
      switch-input-source = [ "<Super>space" ];
    };

    "org/gnome/mutter/wayland/keybindings" = {
      restore-shortcuts = [ ];
    };

    "org/gnome/desktop/screensaver" = {
      picture-uri = "file:///home/nelson/Pictures/Wallpapers/desktop.jpg";
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
      tile-by-default = true;
      smart-gaps = false;
      gap-inner = mkUint32 3;
      gap-outer = mkUint32 3;
      tile-enter = [ "<Super><Shift>Return" ];
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
