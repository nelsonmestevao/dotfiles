{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./programs/gnome.nix
    ./lib
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.packages = with pkgs; [
    # core utils
    bat
    curl
    dig
    dust
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
    mpv
    nushell
    ouch
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
    eva
    # espanso-wayland
    httpie
    k6
    llvmPackages_20.clang-tools
    shellcheck
    shfmt
    stripe-cli
    typst
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
    texliveFull

    # desktop apps
    bitwarden-desktop
    calibre
    digikam
    gimp
    inkscape
    libreoffice
    pinta
    zeal

    # fonts
    font-awesome
    nerd-fonts.hack
    nerd-fonts.noto
    nerd-fonts.jetbrains-mono
    noto-fonts-color-emoji

    # project dependencies

    ## system utils
    inotify-tools

    ## pdf documents
    k2pdfopt
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
    mise
    # elixir_1_18
    # erlang_27
    # ghc
    # nodejs_22
    ruby_3_4

    # misc
    cpufetch
    fastfetch
    figlet
    neofetch
    nix-search-tv
    onefetch
    terminaltexteffects

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

    (
      let
        flakeLockPath = ../flake.lock;
      in
      pkgs.writeShellScriptBin "pkgversion" ''
        PACKAGE="$1"
        REVISION="$2"

        [[ -z "$PACKAGE" ]] && echo "Package name is required" && exit 1
        [[ -z "$REVISION" ]] && REVISION=$(${pkgs.jq}/bin/jq -r '.nodes.nixpkgs.original.ref' ${flakeLockPath})

        echo $(nix eval --raw "github:NixOS/nixpkgs/$REVISION#$PACKAGE.version")
      ''
    )

    (pkgs.writeShellScriptBin "wake-hades" ''
      ${pkgs.wakeonlan}/bin/wakeonlan 2c:f0:5d:59:3c:0d
    '')
  ];

  # home.file.".config/teste/cena.txt" = config.lib.dotfiles.mkSymlink "nixos/cena.txt";
  # xdg.configFile."teste/coisito.txt" = config.lib.dotfiles.mkSymlink "nixos/cena.txt";
  # xdg.configFile."teste/hey.txt" = config.lib.dotfiles.mkSymlink "nixos/cena-nao-existente.txt";

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.nh.enable = true;
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    desktop = "$HOME/Desktop";
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    publicShare = "$HOME/Public";
    templates = "$HOME/Code";
    videos = "$HOME/Videos";
  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05";
}
