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
        fop
        gnupg
        gping
        grex
        gvfs
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
        # age
        bc

        eva

        k6
        llvmPackages_20.clang-tools
        silicon
        stripe-cli

        # containers & cloud
        cloudflared

        # ISO tools
        impression

        # performance & benchmarking
        scc
        tokei

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
