{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./programs/elixir.nix
    ./programs/golang.nix
    ./programs/haskell.nix
    ./programs/nodejs.nix
    ./programs/python.nix
    ./programs/ruby.nix

    ./programs/direnv.nix
    ./programs/ghostty.nix
    ./programs/git.nix
    ./programs/gnome.nix
    ./programs/latex.nix
    ./programs/mise.nix
    ./programs/nvim.nix
    ./programs/sqlite.nix

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
    eva
    # espanso-wayland
    httpie
    k6
    llvmPackages_20.clang-tools
    presenterm
    shellcheck
    shfmt
    stripe-cli
    typst
    watchman

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
    sc-im

    # TUIs
    lazydocker
    lazysql

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

    # misc
    cpufetch
    fastfetch
    figlet
    neofetch
    nix-search-tv
    onefetch
    terminaltexteffects

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

    (pkgs.writeShellScriptBin "gensecret" ''
      SIZE="$1"

      [[ -z "$SIZE" ]] && SIZE="32"

      ${pkgs.openssl}/bin/openssl rand -hex "$SIZE"
    '')

    (pkgs.writeShellScriptBin "wake-hades" ''
      ${pkgs.wakeonlan}/bin/wakeonlan 2c:f0:5d:59:3c:0d
    '')
  ];

  # home.file.".config/teste/cena.txt" = config.lib.dotfiles.mkSymlink "nixos/cena.txt";
  # xdg.configFile."teste/coisito.txt" = config.lib.dotfiles.mkSymlink "nixos/cena.txt";
  # xdg.configFile."teste/hey.txt" = config.lib.dotfiles.mkSymlink "nixos/cena-nao-existente.txt";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.nh.enable = true;
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05";
}
