# Small shell commands installed alongside the package list, kept out of
# packages.nix so that file stays a plain list of package names.
#
# Returns a list of derivations, appended to `home.packages` by packages.nix —
# so these inherit its `dotfiles.packages.enable` gate rather than restating it.
{ pkgs }:
[
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
]
