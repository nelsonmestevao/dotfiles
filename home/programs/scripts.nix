# Small shell commands of my own, by name. plain.nix, next to this file, adds
# them to its list, so each one is a program that a user file turns on.
{ pkgs }:
let
  # Pick two generations with fzf and diff them with nvd. Home-manager and
  # NixOS generations differ only in their profile folder and link prefix, so
  # hm-diff and nixos-diff share this one script. Its stat and date are GNU's,
  # from nixpkgs, since a Mac's take other flags.
  mkGenerationDiff =
    name: dir: prefix:
    pkgs.writeShellScriptBin name ''
      PATH=${pkgs.coreutils}/bin:$PATH
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
{
  pkgversion = pkgs.writeShellScriptBin "pkgversion" ''
    PACKAGE="$1"
    REVISION="''${2:-${(pkgs.lib.importJSON ../../flake.lock).nodes.nixpkgs.original.ref}}"

    [[ -z "$PACKAGE" ]] && echo "Package name is required" && exit 1

    echo $(nix eval --raw "github:NixOS/nixpkgs/$REVISION#$PACKAGE.version")
  '';

  wake-hades = pkgs.writeShellScriptBin "wake-hades" ''
    ${pkgs.wakeonlan}/bin/wakeonlan 2c:f0:5d:59:3c:0d
  '';

  # Nix leaves $HOME alone (only ${ interpolates), so the shell expands it.
  hm-diff = mkGenerationDiff "hm-diff" "$HOME/.local/state/nix/profiles" "home-manager-";
  nixos-diff = mkGenerationDiff "nixos-diff" "/nix/var/nix/profiles" "system-";
}
