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
  };
  modules = [
    { nixpkgs.overlays = overlays; }
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
  ++ importModules mkSystemModule ../system/modules/nixos;
}
