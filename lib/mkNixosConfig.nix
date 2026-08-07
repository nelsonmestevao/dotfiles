{ nixpkgs, vicinae }:
hostname: cfg:
let
  lib = nixpkgs.lib;
  listDirectories = import ./listDirectories.nix { inherit lib; };
  mkSystemModule = import ../system/lib/mkSystemModule.nix { inherit lib; };
  systemModules = map (
    name: mkSystemModule name (import ../system/modules/nixos/${name}/${name}.nix)
  ) (listDirectories ../system/modules/nixos);
in
nixpkgs.lib.nixosSystem {
  inherit (cfg) system;
  specialArgs = {
    inherit hostname vicinae;
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
