{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "nelson";
  home.homeDirectory = "/home/nelson";

  imports = [
    ./programs/gnome.nix
  ];

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
    # core utils
    bat
    curl
    dig
    eza
    fd
    ffmpeg-full
    fop
    fzf
    gnupg
    gvfs
    imagemagick
    jq
    lftp
    poppler_utils # pdftotext, pdftohtml, etc
    ripgrep
    tldr
    unzip
    vdhcoapp
    wget
    yazi
    zoxide
    zsh

    # build tools
    autoconf
    automake
    gcc
    gnumake
    pkg-config

    # development tools
    age
    ast-grep
    bc
    bitwarden-cli
    bruno
    direnv
    # espanso-wayland
    httpie
    k6
    llvmPackages_20.clang-tools
    shellcheck
    shfmt
    stripe-cli
    typst
    wakeonlan
    watchman

    # version control
    delta
    difftastic
    gh
    git
    git-who
    gitleaks
    jujutsu

    # containers & cloud
    cloudflared
    podman
    podman-compose

    # ISO tools
    impression

    # performance & benchmarking
    btop
    hyperfine
    scc
    speedtest-cli

    # editors & IDEs
    neovim
    sc-im

    # desktop apps
    bitwarden-desktop
    calibre
    digikam
    gimp
    inkscape
    libreoffice
    zeal

    # project dependencies

    ## system utils
    inotify-tools

    ## pdf documents
    wkhtmltopdf

    ## image processing and optimization
    file
    image_optim
    # gifsicle
    # jpegoptim
    # libwebp
    nodePackages.svgo
    # optipng
    # pngquant

    ## programming environments
    # mise
    # elixir_1_18
    # erlang_27
    ghc
    # nodejs_22
    ruby_3_4

    # misc
    cpufetch
    neofetch
    onefetch

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    (pkgs.writeShellScriptBin "runex" ''
      FILE="$1"
      TMP="$(mktemp --suffix=.exs)"


      awk '
      /^```elixir/ { inblock = 1; next }
      inblock && /^```/ { inblock = 0; next }
      inblock { print }
      ' "$FILE" > "$TMP"

      elixir "$TMP"
    '')

    (pkgs.writeShellScriptBin "wake-hades" ''
      ${pkgs.wakeonlan}/bin/wakeonlan 2c:f0:5d:59:3c:0d
    '')
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
    EDITOR = "nvim";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
