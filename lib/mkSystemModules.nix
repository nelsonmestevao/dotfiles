{ lib }:
let
  mkSystemModule = import ../system/lib/mkSystemModule.nix { inherit lib; };
in
map (name: mkSystemModule name (import ../system/modules/${name}/${name}.nix)) (
  lib.attrNames (builtins.readDir ../system/modules)
)
