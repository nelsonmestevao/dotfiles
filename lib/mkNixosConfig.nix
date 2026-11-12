{
  nixpkgs,
  vicinae,
  overlays,
}:
hostname:
{ host, users }:
let
  inherit (nixpkgs) lib;
  importModules = import ./importModules.nix { inherit lib; };
  mkSystemModule = import ../system/lib/mkSystemModule.nix;
in
nixpkgs.lib.nixosSystem {
  inherit (host) system;
  # `host` is this host's entry in config/hosts.nix; `users` holds the
  # config/users.nix entries of the users it lists.
  specialArgs = {
    inherit hostname host users;
  };
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
  ++ importModules mkSystemModule "system/modules/nixos";
}
