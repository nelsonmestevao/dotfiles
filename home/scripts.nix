# Small shell commands installed with the package list, kept out of
# packages.nix so that file stays a plain list of package names.
#
# packages.nix adds this list to `home.packages`, so these are installed only
# when `dotfiles.packages.enable` is on, with no check of their own.
{ pkgs }:
let
  # Pick two generations with fzf and diff them with nvd. Home-manager and
  # NixOS generations differ only in their profile folder and link prefix, so
  # hm-diff and nixos-diff share this one script.
  mkGenerationDiff =
    name: dir: prefix:
    pkgs.writeShellScriptBin name ''
      dir="${dir}"
      picks=$(
        for f in "$dir"/${prefix}*-link; do
          name=''${f##*/}
          gen=''${name#${prefix}}
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
    '';
in
[
  (pkgs.writeShellScriptBin "pkgversion" ''
    PACKAGE="$1"
    REVISION="$2"

    [[ -z "$PACKAGE" ]] && echo "Package name is required" && exit 1
    [[ -z "$REVISION" ]] && REVISION=$(${pkgs.jq}/bin/jq -r '.nodes.nixpkgs.original.ref' ${../flake.lock})

    echo $(nix eval --raw "github:NixOS/nixpkgs/$REVISION#$PACKAGE.version")
  '')

  (pkgs.writeShellScriptBin "gensecret" ''
    SIZE="$1"

    [[ -z "$SIZE" ]] && SIZE="32"

    ${pkgs.openssl}/bin/openssl rand -hex "$SIZE"
  '')

  (pkgs.writeShellScriptBin "wake-hades" ''
    ${pkgs.wakeonlan}/bin/wakeonlan 2c:f0:5d:59:3c:0d
  '')

  # Nix leaves $HOME alone (only ${ interpolates), so the shell expands it.
  (mkGenerationDiff "hm-diff" "$HOME/.local/state/nix/profiles" "home-manager-")
  (mkGenerationDiff "nixos-diff" "/nix/var/nix/profiles" "system-")
]
