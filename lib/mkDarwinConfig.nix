{
  nixpkgs,
  nix-darwin,
  overlays,
}:
hostname: cfg:
let
  lib = nixpkgs.lib;
  importModules = import ./importModules.nix { inherit lib; };
  mkSystemModule = import ../system/lib/mkSystemModule.nix;
in
nix-darwin.lib.darwinSystem {
  specialArgs = {
    inherit hostname;
    inherit (cfg) users;
  }
  // import ../system/lib/hostPredicates.nix { inherit lib hostname; };
  modules = [
    {
      nixpkgs.hostPlatform = cfg.system;
      nixpkgs.overlays = overlays;
    }
    ../system/darwin.nix
  ]
  ++ importModules mkSystemModule ../system/modules/darwin;
}
