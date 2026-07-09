{
  nixpkgs,
  nix-darwin,
}:
hostname: cfg:
let
  lib = nixpkgs.lib;
  mkDarwinModule = import ../darwin/lib/mkDarwinModule.nix { inherit lib; };
  darwinModules = map (name: mkDarwinModule name (import ../darwin/modules/${name}/${name}.nix)) (
    lib.attrNames (builtins.readDir ../darwin/modules)
  );
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
    ../darwin
  ]
  ++ darwinModules;
}
