{ nixpkgs, vicinae }:
hostname: cfg:
let
  lib = nixpkgs.lib;
  importModules = import ./importModules.nix { inherit lib; };
  mkSystemModule = import ../system/lib/mkSystemModule.nix;
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
        programs.vicinae.input-server.package = import ./vicinaePackage.nix vicinae cfg.system;
      }
    )
  ]
  ++ importModules mkSystemModule ../system/modules/nixos;
}
