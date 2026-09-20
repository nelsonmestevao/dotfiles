{
  nixpkgs,
  nix-darwin,
}:
hostname: cfg:
let
  lib = nixpkgs.lib;
  listDirectories = import ./listDirectories.nix { inherit lib; };
  mkSystemModule = import ../system/lib/mkSystemModule.nix;
  systemModules = map (
    name: mkSystemModule name (import ../system/modules/darwin/${name}/${name}.nix)
  ) (listDirectories ../system/modules/darwin);
in
nix-darwin.lib.darwinSystem {
  specialArgs = {
    inherit hostname;
    inherit (cfg) users;
  }
  // import ../system/lib/hostPredicates.nix { inherit lib hostname; };
  modules = [
    { nixpkgs.hostPlatform = cfg.system; }
    ../system/darwin.nix
  ]
  ++ systemModules;
}
