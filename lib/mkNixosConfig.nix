{
  nixpkgs,
  vicinae,
  overlays,
}:
hostname: cfg:
let
  lib = nixpkgs.lib;
  importModules = import ./importModules.nix { inherit lib; };
  mkSystemModule = import ../system/lib/mkSystemModule.nix;
in
nixpkgs.lib.nixosSystem {
  inherit (cfg) system;
  specialArgs = {
    inherit hostname;
    inherit (cfg) users;
  }
  // import ../system/lib/hostPredicates.nix { inherit lib hostname; };
  modules = [
    { nixpkgs.overlays = overlays; }
    ../system/nixos.nix
    vicinae.nixosModules.default
    (
      { config, pkgs, ... }:
      {
        # Gate upstream's input-server (default: true) on our per-host flag.
        programs.vicinae.input-server.enable = config.dotfiles.modules.vicinae.enable;
        programs.vicinae.input-server.package = pkgs.vicinae;
      }
    )
  ]
  ++ importModules mkSystemModule ../system/modules/nixos;
}
