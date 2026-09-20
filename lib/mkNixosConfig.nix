{ nixpkgs, vicinae }:
hostname: cfg:
let
  lib = nixpkgs.lib;
  listDirectories = import ./listDirectories.nix { inherit lib; };
  mkSystemModule = import ../system/lib/mkSystemModule.nix;
  systemModules = map (
    name: mkSystemModule name (import ../system/modules/nixos/${name}/${name}.nix)
  ) (listDirectories ../system/modules/nixos);
in
nixpkgs.lib.nixosSystem {
  inherit (cfg) system;
  specialArgs = {
    inherit hostname vicinae;
    inherit (cfg) users;
  }
  // import ../system/lib/hostPredicates.nix { inherit lib hostname; };
  modules = [
    ../system/nixos.nix
    vicinae.nixosModules.default
    (
      { config, ... }:
      {
        # Gate upstream's input-server (default: true) on our per-host flag.
        programs.vicinae.input-server.enable = config.dotfiles.modules.vicinae.enable;
      }
    )
  ]
  ++ systemModules;
}
