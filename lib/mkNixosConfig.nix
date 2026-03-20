{ nixpkgs }:
hostname: cfg:
let
  lib = nixpkgs.lib;
  mkSystemModule = import ../system/lib/mkSystemModule.nix { inherit lib; };
  systemModules = map (name: mkSystemModule name (import ../system/modules/${name}/${name}.nix)) (
    lib.attrNames (builtins.readDir ../system/modules)
  );
in
nixpkgs.lib.nixosSystem {
  inherit (cfg) system;
  specialArgs = {
    inherit hostname;
    inherit (cfg) users;
  };
  modules = [
    ../system
  ]
  ++ systemModules;
}
