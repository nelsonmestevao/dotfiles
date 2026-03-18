{ lib }:
let
  mkHomeModule = import ../home/lib/mkHomeModule.nix { inherit lib; };
in
map (name: mkHomeModule name (import ../home/programs/${name}/${name}.nix)) (
  lib.attrNames (builtins.readDir ../home/programs)
)
