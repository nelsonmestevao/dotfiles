{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.packages;
in
{
  options.dotfiles.packages = {
    enable = lib.mkEnableOption "Enable packages.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # core utils
      curl
      dig
      dust
      eza
      fd
      ffmpeg-full
      fop
      gnupg
      gping
      grex
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
      httpie
      k6
      llvmPackages_20.clang-tools
      presenterm
      shellcheck
      shfmt
      silicon
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
      tokei

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
  };
}
