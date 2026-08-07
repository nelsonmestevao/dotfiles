{
  nixpkgs,
  nix-darwin,
}:
hostname: cfg:
let
  lib = nixpkgs.lib;
  listDirectories = import ./listDirectories.nix { inherit lib; };
  mkSystemModule = import ../system/lib/mkSystemModule.nix { inherit lib; };
  systemModules = map (
    name: mkSystemModule name (import ../system/modules/darwin/${name}/${name}.nix)
  ) (listDirectories ../system/modules/darwin);
in
nix-darwin.lib.darwinSystem {
  specialArgs = {
    inherit hostname;
    inherit (cfg) users;
    # Reuse the generic host predicates from the NixOS side.
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
    { nixpkgs.hostPlatform = cfg.system; }
    ../system/darwin.nix
  ]
  ++ systemModules;
}
