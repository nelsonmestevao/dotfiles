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

      lftp
      mpv
      nushell
      ouch
      poppler-utils # pdftotext, pdftohtml, etc
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

      eva

      k6
      llvmPackages_20.clang-tools
      presenterm
      shellcheck
      shfmt
      silicon
      stripe-cli

      # containers & cloud
      cloudflared

      # ISO tools
      impression

      # performance & benchmarking
      btop
      ctop

      scc
      speedtest-cli
      tokei

      # editors & IDEs
      sc-im

      # TUIs
      lazydocker
      lazysql

      # misc
      cpufetch
      fastfetch
      onefetch

      figlet

      nix-search-tv

      dconf2nix
      cached-nix-shell

      fuse
      appimage-run

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

      (pkgs.writeShellScriptBin "hm-diff" ''
        dir="$HOME/.local/state/nix/profiles"
        picks=$(
          for f in "$dir"/home-manager-*-link; do
            name=''${f##*/}
            gen=''${name#home-manager-}
            gen=''${gen%-link}
            printf '%s  gen %s\t%s\n' \
              "$(date -d "@$(stat -c '%Y' "$f")" '+%Y-%m-%d %H:%M')" \
              "$gen" "$f"
          done | sort -r \
            | ${pkgs.fzf}/bin/fzf --multi --delimiter=$'\t' --with-nth=1 \
                --header 'TAB to mark exactly 2, then Enter' \
            | awk -F'\t' '{print $2}'
        )
        if [ "$(echo "$picks" | grep -c .)" -ne 2 ]; then
          echo "pick exactly 2 generations"; exit 1
        fi
        a=$(echo "$picks" | head -1)
        b=$(echo "$picks" | tail -1)
        if [ "$(stat -c '%Y' "$a")" -lt "$(stat -c '%Y' "$b")" ]; then
          older="$a"; newer="$b"
        else
          older="$b"; newer="$a"
        fi
        ${pkgs.nvd}/bin/nvd diff "$older" "$newer"
      '')

      (pkgs.writeShellScriptBin "nixos-diff" ''
        dir="/nix/var/nix/profiles"
        picks=$(
          for f in "$dir"/system-*-link; do
            name=''${f##*/}
            gen=''${name#system-}
            gen=''${gen%-link}
            printf '%s  gen %s\t%s\n' \
              "$(date -d "@$(stat -c '%Y' "$f")" '+%Y-%m-%d %H:%M')" \
              "$gen" "$f"
          done | sort -r \
            | ${pkgs.fzf}/bin/fzf --multi --delimiter=$'\t' --with-nth=1 \
                --header 'TAB to mark exactly 2, then Enter' \
            | awk -F'\t' '{print $2}'
        )
        if [ "$(echo "$picks" | grep -c .)" -ne 2 ]; then
          echo "pick exactly 2 generations"; exit 1
        fi
        a=$(echo "$picks" | head -1)
        b=$(echo "$picks" | tail -1)
        if [ "$(stat -c '%Y' "$a")" -lt "$(stat -c '%Y' "$b")" ]; then
          older="$a"; newer="$b"
        else
          older="$b"; newer="$a"
        fi
        ${pkgs.nvd}/bin/nvd diff "$older" "$newer"
      '')
    ];
  };
}
