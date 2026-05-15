{ nixpkgs, vicinae }:
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
    onHost = import ../system/lib/onHost.nix {
      inherit (nixpkgs) lib;
      inherit hostname;
    };
    onHosts = import ../system/lib/onHosts.nix {
      inherit (nixpkgs) lib;
      inherit hostname;
    };
  };
  modules = [
    ../system
    vicinae.nixosModules.default
  ]
  ++ systemModules;
}
