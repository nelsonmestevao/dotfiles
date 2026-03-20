{ nixpkgs, systemModules }:
hostname: cfg:
nixpkgs.lib.nixosSystem {
  inherit (cfg) system;
  specialArgs = {
    inherit hostname;
    inherit (cfg) users;
  };
  modules = [
    ../system
  ] ++ systemModules;
}
