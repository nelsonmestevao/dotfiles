{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.packages;
  scripts = import ./scripts.nix { inherit pkgs; };
in
{
  options.dotfiles.packages = {
    enable = lib.mkEnableOption "Enable packages.";
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        # core utils
        dig
        dust
        ffmpeg-full
        fop
        gnupg
        gping
        grex
        gvfs
        imagemagick
        libsecret

        lftp
        mpv
        nushell
        ouch
        poppler-utils # pdftotext, pdftohtml, etc
        tldr
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

        eva

        k6
        llvmPackages_20.clang-tools
        presenterm
        silicon
        stripe-cli

        # containers & cloud
        cloudflared

        # ISO tools
        impression

        # performance & benchmarking
        scc
        tokei

        # editors & IDEs
        sc-im

        # TUIs
        lazysql

        # misc
        nix-search-tv

        dconf2nix
        cached-nix-shell

        fuse
        appimage-run

        terminaltexteffects
      ]
      ++ scripts;
  };
}
